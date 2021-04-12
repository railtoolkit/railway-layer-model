#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

include("../src/BaseLayer.jl")

module TestBaseLayer

file_path = "data/network.yaml"

baseLayer = Main.BaseLayer.importBaseLayer(file_path)
Main.BaseLayer.showBaseLayer(baseLayer["graph"],baseLayer["nodeNames"],baseLayer["nodeCoords"],baseLayer["edgeNames"])

# Test for baseLayer if connection is possible without "kopfmachen"

end # module TestBaseLayer
