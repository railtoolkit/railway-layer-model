#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using MetaGraphs, YAML, JSON, JSONSchema
using Compose, Cairo, Fontconfig # packages for saving the plot as PDF
using CSV, Tables

cd("DSR_cycles/3/")

include("../../../src/LMcore.jl")
import .LMcore
include("../../../src/BaseLayer.jl")
import .BaseLayer
include("../../../src/NetworkLayer.jl")
import .NetworkLayer
include("../../../src/PhysicalLayer.jl")
import .PhysicalLayer

baseLayerFile = "example/base.yaml"
networkLayerFile = "example/network.yaml"
physicalLayerFile = "example/physical.yaml"
schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(networkLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))
files = readdir("snippets")
for file in files
    println(validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open("snippets/" * file))))
end

networkLayer = NetworkLayer.load(networkLayerFile)
fig = LMcore.show(networkLayer)
draw(PDF("network2.pdf", 42cm, 18cm), fig)# save the plot
