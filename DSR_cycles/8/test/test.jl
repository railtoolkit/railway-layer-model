#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using YAML, JSON, JSONSchema, Graphs, MetaGraphs
using DataFrames, TrainRuns
using CairoMakie  # packages for saving the plot as PDF

cd("DSR_cycles/8/")

include("../../../src/LMcore.jl")
import .LMcore
include("../../../src/BaseLayer.jl")
import .BaseLayer
include("../../../src/PhysicalLayer.jl")
import .PhysicalLayer
include("../../../src/SpeedProfileLayer.jl")
import .SpeedProfileLayer
include("../../../src/NetworkLayer.jl")
import .NetworkLayer
include("../../../src/InterlockingLayer.jl")
import .InterlockingLayer
include("../../../src/ResourceLayer.jl")
import .ResourceLayer
include("../../../src/TransitLayer.jl")
import .TransitLayer
include("../../../src/TransportLayer.jl")
import .TransportLayer

baseLayerFile = "example/base.yaml"
networkLayerFile = "example/network.yaml"
physicalLayerFile = "example/physical.yaml"
speedprofileLayerFile = "example/speedprofile.yaml"
interlockingLayerFile = "example/interlocking.yaml"
resourceLayerFile = "example/resource.yaml"
transitLayerFile = "example/transit.yaml"
tranportLayerFile = "example/transport.yaml"

schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(networkLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(speedprofileLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(interlockingLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(resourceLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(transitLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(tranportLayerFile)))
files = readdir("snippets")
files[1] == ".DS_Store" ? popfirst!(files) : nothing
for file in files
  println(validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open("snippets/" * file))))
end

physicalLayer = PhysicalLayer.load(physicalLayerFile)
interlockingLayer = InterlockingLayer.load(interlockingLayerFile)
networkLayer = NetworkLayer.load(networkLayerFile)
resourceLayer = ResourceLayer.load(resourceLayerFile)
speedprofileLayer = SpeedProfileLayer.load(speedprofileLayerFile)
transitLayer = TransitLayer.loadSnippets(transitLayerFile)

#############################################
## information for the transportLayerFile
#############################################

running_path = [
  (link = "XR",      track = "3",         route = "main"),
  (link = "XR_XPD",  track = "XR_XPD",    route = "main"),
  (link = "XPD",     track = "1",         route = "main"),
  (link = "XPD_XBU", track = "XPD_XBU",   route = "main"),
  (link = "XBU_XSZ", track = "XBU_XSZ_2", route = "main"),
  (link = "XSZ",     track = "2",         route = "main")
]

line_sections = [
  (id = "9724_forward",       begining =  0.0, ending = 18.9),
  (id = "9721_right_forward", begining = 32.1, ending = 38.0),
]

trains = Dict()
push!(trains, :freight => TrainRuns.Train("test/freight_train.yaml"))
push!(trains, :local   => TrainRuns.Train("test/local_train.yaml"))
settings = TrainRuns.Settings(outputDetail=:driving_course)
# settings = TrainRuns.Settings(outputDetail=:driving_course)

trainlegs = [
  # (name = "pax_leg1_1",   start = "XR:H3_2:berth:front",  finish = "XPD:H1_2:berth:front", train = :local),
  (name = "pax_leg1_2",   start = "XR:H3_2:berth:front",  finish = "XPD:H1_4:berth:front", train = :local),
  # (name = "pax_leg2_1",   start = "XPD:H1_2:berth:front", finish = "XSZ:H2_2:berth:front", train = :local),
  (name = "pax_leg2_2",   start = "XPD:H1_4:berth:front", finish = "XSZ:H2_2:berth:front", train = :local),
  # (name = "freight_pass", start = "X:fictitious:X:front", finish = "Y:fictitious:Y:front", train = :freight),
  (name = "freight_leg1", start = "XR:N3:berth:front",    finish = "XPD:N1:berth:front",   train = :freight),
  (name = "freight_leg2", start = "XPD:N1:berth:front",   finish = "XSZ:N2:berth:front",   train = :freight)
]
# CSV.write("run.csv", running_times[:pax_leg1_2], delim=';',decimal=',') # DEBUG

minimum_dwell_time = 240.0 # in seconds
minimum_buffer_time = 60.0 # in seconds

## route check

routes = InterlockingLayer.routes_of_running_path(running_path,networkLayer,interlockingLayer)
# TODO: get speed restriction from route including overlap
# TODO: test if two running_paths have route conflict
characteristic_sections = TransitLayer.get_characteristic_sections(speedprofileLayer, line_sections)

## points_of_interest
points_of_interest = ResourceLayer.get_poi(running_path, networkLayer, resourceLayer, physicalLayer, interlockingLayer)
points_of_interest[!, "measure"] = @. ifelse(occursin("clearing",points_of_interest.Type), "rear", "front")
points_of_interest[!, "label"] = points_of_interest.NetworkElement .* ":" .* points_of_interest.Object .* ":" .* points_of_interest.Type
ResourceLayer.unify_mileage!(points_of_interest, "9721", 32.1-18.9)
rename!(points_of_interest, :Position => :position)
select!(points_of_interest, [:position,:measure,:label])
for row in eachrow(points_of_interest)
  if row.measure == "rear"
    position = row.position
    label = row.label * ":front"
    push!(points_of_interest, (position, "front", label))
    row.label *= ":rear"
  else
    row.label *= ":front"
  end
end
points_of_interest.position = points_of_interest.position .* 1000

## running time calculation

function getPosition(label)
  return first(filter(row -> row.label == label, points_of_interest)[!,:position])
end

running_times = Dict()
for trainleg in trainlegs
  # println(trainleg.name)
  moving_section = TransitLayer.getMovingSection(characteristic_sections, getPosition(trainleg.start), getPosition(trainleg.finish))
  path = TrainRuns.Path(moving_section, points_of_interest, name=trainleg.name)
  run = TrainRuns.trainrun(trains[trainleg.train], path, settings)
  TransitLayer.addClearingAtEdge!(run,physicalLayer)
  push!(running_times, Symbol(trainleg.name) => run)
end

##

## freight train
freight_train1 = "freight_leg1"
freight_train2 = "freight_leg2"
run_freight1 = running_times[Symbol(freight_train1)]
run_freight2 = running_times[Symbol(freight_train2)]
blockingtimes_freight1 = TransportLayer.getBlockingTimesFromSnippets(transitLayer, freight_train1, run_freight1.s[1], run_freight1.t[2], aggregated = true)
blockingtimes_freight2 = TransportLayer.getBlockingTimesFromSnippets(transitLayer, freight_train2, run_freight2.s[1], run_freight2.t[2], aggregated = true)

## passenger train
pax_train1 = "pax_leg1_2"
pax_train2 = "pax_leg2_2"
run_pax1 = running_times[Symbol(pax_train1)]
run_pax2 = running_times[Symbol(pax_train2)]
blockingtimes_pax1 = TransportLayer.getBlockingTimesFromSnippets(transitLayer, pax_train1, run_pax1.s[1], run_pax1.t[2], aggregated = true)
blockingtimes_pax2 = TransportLayer.getBlockingTimesFromSnippets(transitLayer, pax_train2, run_pax2.s[1], run_pax2.t[2], aggregated = true)

fig = TransportLayer.svtPlot()
TransportLayer.addTrain!(fig,run_freight1,blockingtimes_freight1,color = :blue)
t_offset_pax = TransportLayer.minimumHeadway(blockingtimes_freight1,blockingtimes_pax1) + minimum_buffer_time
TransportLayer.addTrain!(fig,run_pax1,blockingtimes_pax1,color = :red, t_offset = t_offset_pax)

dwell_time_pax = TransportLayer.dwellTime(minimum_dwell_time, t_offset = maximum(skipmissing(run_pax1.t)) + t_offset_pax, s_offset = run_pax1.s[end])
TransportLayer.addTrain!(fig,dwell_time_pax,color = :red)
TransportLayer.addTrain!(fig,run_pax2,blockingtimes_pax2, t_offset = dwell_time_pax.t[end], color = :red)

t_offset_freight = TransportLayer.minimumHeadway(blockingtimes_pax2,blockingtimes_freight2) + dwell_time_pax.t[end] + minimum_buffer_time
TransportLayer.addTrain!(fig,run_freight2,blockingtimes_freight2,color = :blue,t_offset=t_offset_freight)

dwell_time_freight = TransportLayer.dwellTime((t_offset_freight - run_freight1.t[end-1]), t_offset = maximum(skipmissing(run_freight1.t)), s_offset = run_freight1.s[end] )
TransportLayer.addTrain!(fig,dwell_time_freight,color = :blue)

CairoMakie.save("timetable.pdf", fig)# save the plot
