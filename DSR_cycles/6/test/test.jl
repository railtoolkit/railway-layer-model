#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using MetaGraphs, Graphs, YAML, JSON, JSONSchema
using Compose, Cairo, Fontconfig # packages for saving the plot as PDF
using CSV, Tables, DataFrames

cd("DSR_cycles/6/")

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

baseLayerFile = "example/base.yaml"
networkLayerFile = "example/network.yaml"
physicalLayerFile = "example/physical.yaml"
speedprofileLayerFile = "example/speedprofile.yaml"
interlockingLayerFile = "example/interlocking.yaml"
resourceLayerFile = "example/resource.yaml"

schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(networkLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(speedprofileLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(interlockingLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(resourceLayerFile)))
files = readdir("snippets")
files[1] == ".DS_Store" ? popfirst!(files) : nothing
for file in files
  println(validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open("snippets/" * file))))
end


physicalLayer = PhysicalLayer.load(physicalLayerFile)
interlockingLayer = InterlockingLayer.load(interlockingLayerFile)
networkLayer = NetworkLayer.load(networkLayerFile)
resourceLayer = ResourceLayer.load(resourceLayerFile)

fig = LMcore.show(networkLayer)
draw(PDF("network.pdf", 42cm, 18cm), fig)# save the plot


# trigger point, view point, breaking point/distant signal, main signal, clearing point
path = [("XR","3"),("XR_XPD","XR_XPD"),("XPD","1"),("XPD_XBU","XPD_XBU"),("XBU_XSZ","XBU_XSZ_2"),("XSZ","2")]

points_of_interest = ResourceLayer.get_poi(path, networkLayer, resourceLayer, physicalLayer, interlockingLayer)
