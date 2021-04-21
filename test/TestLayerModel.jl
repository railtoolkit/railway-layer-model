#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

include("src/BaseLayer.jl")

module TestBaseLayer

load_file = "data/base_layer.yaml"
save_file = "test/base_layer.yaml"

@time baseLayer = Main.BaseLayer.loadBaseLayer(load_file)

@time Main.BaseLayer.showBaseLayer(baseLayer)

@time Main.BaseLayer.saveBaseLayer(baseLayer, save_file)

end # module TestBaseLayer