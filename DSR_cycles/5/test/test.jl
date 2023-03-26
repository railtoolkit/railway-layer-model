#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using MetaGraphs, Graphs, YAML, JSON, JSONSchema
using CSV, Tables, DataFrames

cd("DSR_cycles/5/")

include("../../../src/LMcore.jl")
import .LMcore
include("../../../src/BaseLayer.jl")
import .BaseLayer
include("../../../src/PhysicalLayer.jl")
import .PhysicalLayer
include("../../../src/SpeedProfileLayer.jl")
import .SpeedProfileLayer
include("../../../src/InterlockingLayer.jl")
import .InterlockingLayer

baseLayerFile = "example/base.yaml"
networkLayerFile = "example/network.yaml"
physicalLayerFile = "example/physical.yaml"
interlockingLayerFile = "example/interlocking.yaml"

schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(networkLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(interlockingLayerFile)))
files = readdir("snippets")
files[1] == ".DS_Store" ? popfirst!(files) : nothing
for file in files
  println(validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open("snippets/" * file))))
end


physicalLayer = PhysicalLayer.load(physicalLayerFile)
interlockingLayer = InterlockingLayer.load(interlockingLayerFile)
InterlockingLayer.selectLimit!(interlockingLayer, "XPD_west" ) # only one interlocking limit

interlocking_elements = PhysicalLayer.get_route_elements(physicalLayer)
route_table = InterlockingLayer.get_route_table(interlockingLayer, interlocking_elements)
CSV.write("route_table.csv",route_table)

route_conflicts = InterlockingLayer.get_route_conflicts(route_table, interlocking_elements)
CSV.write("route_conflicts.csv",route_conflicts)
