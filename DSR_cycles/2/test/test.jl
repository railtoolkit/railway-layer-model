#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using MetaGraphs, YAML, JSON, JSONSchema
using Compose, Cairo, Fontconfig # packages for saving the plot as PDF
using CSV, Tables

cd("DSR_cycles/2/")

include("../../../src/LMcore.jl")
import .LMcore
include("../../../src/BaseLayer.jl")
import .BaseLayer
include("../../../src/PhysicalLayer.jl")
import .PhysicalLayer

baseLayerFile = "example/base.yaml"
physicalLayerFile = "example/physical.yaml"
schemaFile = "schema/layer_model.json"
isvalid(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
isvalid(Schema(JSON.parsefile(schemaFile)), YAML.load(open(physicalLayerFile)))

physicalLayer = PhysicalLayer.load(physicalLayerFile)
fig = LMcore.show(physicalLayer)
draw(PDF("physical.pdf", 42cm, 18cm), fig)# save the plot

distmx = get_prop(physicalLayer, :distances)
CSV.write("distmx_physical.csv",  Tables.table(distmx), writeheader=false)


crossing = PhysicalLayer.load("snippets/crossing.yaml")
fig = LMcore.show(crossing)

files = readdir("snippets")

for file in files
    println(validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open("snippets/" * file))))
end