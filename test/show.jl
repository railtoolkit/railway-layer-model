#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using JSON, JSONSchema, YAML, CSV
# using YAML, JSON, JSONSchema, Graphs, MetaGraphs
# using DataFrames, TrainRuns
# using CairoMakie  # packages for saving the plot as PDF


include("../src/LMcore.jl")
import .LMcore
include("../src/BaseLayer.jl")
import .BaseLayer
include("../src/PhysicalLayer.jl")
import .PhysicalLayer
include("../src/SpeedProfileLayer.jl")
import .SpeedProfileLayer
include("../src/NetworkLayer.jl")
import .NetworkLayer
include("../src/InterlockingLayer.jl")
import .InterlockingLayer
include("../src/ResourceLayer.jl")
import .ResourceLayer
include("../src/TransitLayer.jl")
import .TransitLayer
include("../src/TransportLayer.jl")
import .TransportLayer

baseLayerFile = "data/layer/base.yaml"
networkLayerFile = "data/layer/network.yaml"
physicalLayerFile = "data/layer/physical.yaml"
speedprofileLayerFile = "data/layer/speedprofile.yaml"
interlockingLayerFile = "data/layer/interlocking.yaml"
resourceLayerFile = "data/layer/resource.yaml"
transitLayerFile = "data/layer/transit.yaml"
tranportLayerFile = "data/layer/transport.yaml"

schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(networkLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(speedprofileLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(interlockingLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(resourceLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(transitLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(tranportLayerFile)))

baseLayer = BaseLayer.load(baseLayerFile)
physicalLayer = PhysicalLayer.load(physicalLayerFile)
networkLayer = NetworkLayer.load(networkLayerFile)
speedprofileLayer = SpeedProfileLayer.load(speedprofileLayerFile)
interlockingLayer = InterlockingLayer.load(interlockingLayerFile)
resourceLayer = ResourceLayer.load(resourceLayerFile)
transitLayer = TransitLayer.loadSnippets(transitLayerFile)

fig = LMcore.show(baseLayer)
fig = LMcore.show(physicalLayer)
fig = LMcore.show(networkLayer)

## todo wrap in SpeedProfileLayer function including plot
start_mileage = speedprofileLayer[1]["start"]
end_mileage = speedprofileLayer[1]["end"]
id = speedprofileLayer[1]["id"]
allowance = SpeedProfileLayer.allowanceTable(speedprofileLayer, id)
gradient = SpeedProfileLayer.gradientTable(speedprofileLayer, id)
curvature = SpeedProfileLayer.curvatureTable(speedprofileLayer, id)
SpeedProfileLayer.cutAllowanceTable!(allowance, start_mileage, end_mileage)
SpeedProfileLayer.cutGradientTable!(gradient, start_mileage, end_mileage)
SpeedProfileLayer.cutCurvatureTable!(curvature, start_mileage, end_mileage)
CSV.write("speed_allowance.csv",allowance)
CSV.write("speed_gradient.csv",gradient)
CSV.write("speed_curvature.csv",curvature)
