#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

using MetaGraphs, YAML, JSON, JSONSchema
using CSV, Tables, DataFrames

cd("DSR_cycles/4/")

include("../../../src/LMcore.jl")
import .LMcore
include("../../../src/BaseLayer.jl")
import .BaseLayer
include("../../../src/SpeedProfileLayer.jl")
import .SpeedProfileLayer

baseLayerFile = "example/base.yaml"
speedprofileLayerFile = "example/speedprofile.yaml"
schemaFile = "schema/layer_model.json"
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(baseLayerFile)))
validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open(speedprofileLayerFile)))
files = readdir("snippets")
files[1] == ".DS_Store" ? popfirst!(files) : nothing
for file in files
    println(validate(Schema(JSON.parsefile(schemaFile)), YAML.load(open("snippets/" * file))))
end

speedprofileLayer = SpeedProfileLayer.load(speedprofileLayerFile)

df1 = SpeedProfileLayer.curvatureTable(speedprofileLayer, "9724_forward")
df2 = SpeedProfileLayer.curvatureTable(speedprofileLayer, "9721_right_forward")

SpeedProfileLayer.cutCurvatureTable!(df1, 7.9, 18.9)
SpeedProfileLayer.cutCurvatureTable!(df2, 32.1, 38.0)

df = SpeedProfileLayer.joinCurvatureTable(df1,df2)
CSV.write("speed_radius.csv",df)

df1 = SpeedProfileLayer.allowanceTable(speedprofileLayer, "9724_forward")
df2 = SpeedProfileLayer.allowanceTable(speedprofileLayer, "9721_right_forward")

SpeedProfileLayer.cutAllowanceTable!(df1, 7.9, 18.9)
SpeedProfileLayer.cutAllowanceTable!(df2, 32.1, 38.0)

df = SpeedProfileLayer.joinAllowanceTable(df1,df2)
CSV.write("speed_allowance.csv",df)

df1 = SpeedProfileLayer.gradientTable(speedprofileLayer, "9724_forward")
df2 = SpeedProfileLayer.gradientTable(speedprofileLayer, "9721_right_forward")

SpeedProfileLayer.cutGradientTable!(df1, 7.9, 18.9)
SpeedProfileLayer.cutGradientTable!(df2, 32.1, 38.0)

df = joinGradientTable(df1,df2)
CSV.write("speed_gradient.csv",df)