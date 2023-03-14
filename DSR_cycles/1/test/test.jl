#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using MetaGraphs, YAML, JSON, JSONSchema
using Compose, Cairo, Fontconfig # packages for saving the plot as PDF
using CSV, Tables

cd("DSR_cycles/1/")

include("../../../src/LMcore.jl")
import .LMcore
include("../../../src/BaseLayer.jl")
import .BaseLayer

baseLayerFile = "example/base.yaml"
schemaFile = "schema/layer_model.json"
isvalid(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))

baseLayer = BaseLayer.load(baseLayerFile)
fig = LMcore.show(baseLayer)
draw(PDF("base.pdf", 16cm, 6cm), fig)# save the plot

distmx = get_prop(baseLayer, :distances)
CSV.write("distmx_base.csv",  Tables.table(distmx), writeheader=false)
