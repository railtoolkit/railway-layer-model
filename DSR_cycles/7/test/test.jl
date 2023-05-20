#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using YAML, JSON, JSONSchema
# using Compose, Cairo, Fontconfig # packages for saving the plot as PDF
using DataFrames, TrainRuns

cd("DSR_cycles/7/")

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

baseLayerFile = "example/base.yaml"
networkLayerFile = "example/network.yaml"
physicalLayerFile = "example/physical.yaml"
speedprofileLayerFile = "example/speedprofile.yaml"
interlockingLayerFile = "example/interlocking.yaml"
resourceLayerFile = "example/resource.yaml"
transitLayerFile = "example/transit.yaml"

schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(networkLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(speedprofileLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(interlockingLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(resourceLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(transitLayerFile)))
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
## creating the transitLayerFile
#############################################

## characteristic_sections
allowance1 = SpeedProfileLayer.allowanceTable(speedprofileLayer, "9724_forward")
allowance2 = SpeedProfileLayer.allowanceTable(speedprofileLayer, "9721_right_forward")
SpeedProfileLayer.cutAllowanceTable!(allowance2, 32.1, 38.0)
allowance = SpeedProfileLayer.joinAllowanceTable(allowance1,allowance2,32.1-18.9)
select!(allowance, [:Position,:Allowance])
gradient1 = SpeedProfileLayer.gradientTable(speedprofileLayer, "9724_forward")
gradient2 = SpeedProfileLayer.gradientTable(speedprofileLayer, "9721_right_forward")
SpeedProfileLayer.cutGradientTable!(gradient1, 0.0, 18.9)
SpeedProfileLayer.cutGradientTable!(gradient2, 32.1, 38.0)
gradient = SpeedProfileLayer.joinGradientTable(gradient1,gradient2,32.1-18.9)
select!(gradient, [:Position,:Slope])
characteristic_sections = outerjoin(allowance, gradient, on = :Position)
sort!(characteristic_sections, [:Position])
allowance = missing
slope = missing
for row in eachrow(characteristic_sections)
  ismissing(row[:Allowance]) ? row[:Allowance] = allowance : allowance = row[:Allowance]
  ismissing(row[:Slope]) ? row[:Slope] = slope : slope = row[:Slope]
end
rename!(characteristic_sections, :Position => :position, :Slope => :resistance, :Allowance => :speed )
# CSV.write("characteristic_sections.csv", characteristic_sections, delim=';',decimal=',')
TransitLayer.extendCharacteristicSections!(characteristic_sections, 3.0)

## points_of_interest
running_path = [("XR","3"),("XR_XPD","XR_XPD"),("XPD","1"),("XPD_XBU","XPD_XBU"),("XBU_XSZ","XBU_XSZ_2"),("XSZ","2")]
points_of_interest = ResourceLayer.get_poi(running_path, networkLayer, resourceLayer, physicalLayer, interlockingLayer)
ResourceLayer.unify_mileage!(points_of_interest, "9721", 32.1-18.9)
points_of_interest[!, "measure"] = @. ifelse(occursin("clearing",points_of_interest.Type), "rear", "front")
points_of_interest[!, "label"] = points_of_interest.NetworkElement .* ":" .* points_of_interest.Object .* ":" .* points_of_interest.Type
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
ResourceLayer.add_poi!(points_of_interest, -3.0, "front", "X:fictitious:X:front")
ResourceLayer.add_poi!(points_of_interest, 28.0, "front", "Y:fictitious:Y:front")
# CSV.write("points_of_interest.csv", points_of_interest, delim=';',decimal=',')


## SI - units
characteristic_sections.speed = characteristic_sections.speed ./3.6
characteristic_sections.position = characteristic_sections.position .* 1000
points_of_interest.position = points_of_interest.position .* 1000

## running time calculation
trains = Dict()
push!(trains, :freight => TrainRuns.Train("test/freight_train.yaml"))
push!(trains, :local   => TrainRuns.Train("test/local_train.yaml"))
settings = TrainRuns.Settings(outputDetail=:points_of_interest)
# settings = TrainRuns.Settings(outputDetail=:driving_course)

trainlegs = [
  (name = "pax_leg1_1",   start = "XR:H3_2:berth:front",  finish = "XPD:H1_2:berth:front", train = :local),
  (name = "pax_leg1_2",   start = "XR:H3_2:berth:front",  finish = "XPD:H1_4:berth:front", train = :local),
  (name = "pax_leg2_1",   start = "XPD:H1_2:berth:front", finish = "XSZ:H2_2:berth:front", train = :local),
  (name = "pax_leg2_2",   start = "XPD:H1_4:berth:front", finish = "XSZ:H2_2:berth:front", train = :local),
  (name = "freight_pass", start = "X:fictitious:X:front", finish = "Y:fictitious:Y:front", train = :freight),
  (name = "freight_leg1", start = "XR:N3:berth:front",    finish = "XPD:N1:berth:front",   train = :freight),
  (name = "freight_leg2", start = "XPD:N1:berth:front",   finish = "XSZ:N2:berth:front",   train = :freight)
]

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

snippetInfos = Dict()
snippetLegs = Dict()
for trainleg in trainlegs
  # println(trainleg)
  snippetInfo = TransitLayer.getSnippetInfo(running_times[Symbol(trainleg.name)])
  push!(snippetInfos, Symbol(trainleg.name) => snippetInfo)
  snippets = []
  for row in eachrow(snippetInfo)
    snippet = TransitLayer.getSnippet(running_times[Symbol(trainleg.name)],row.ingress,row.egress, type = row.type, name = string(trainleg.name) * ", " * string(row.type) )
    push!(snippets, snippet)
  end
  push!(snippetLegs, Symbol(trainleg.name) => snippets)
end

for key in keys(snippetLegs)
  TransitLayer.saveSnippets("tmp_" * string(key) * ".yaml",snippetLegs[key])
end
