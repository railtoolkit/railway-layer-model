#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

include("src/LMcore.jl")

include("src/BaseLayer.jl")
include("src/PhysicalLayer.jl")

module TestBaseLayer

@time baseLayer = Main.BaseLayer.loadBaseLayer("data/base_layer.yaml")
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("data/physical_layer.yaml")
@time test = Main.PhysicalLayer.loadPhysicalLayer("data/snippets/test_rail_path.yaml")

@time Main.LMcore.showGraph(baseLayer)
@time Main.LMcore.showGraph(physicalLayer)

@time Main.BaseLayer.saveBaseLayer(baseLayer, "test/base_layer.yaml")
@time Main.PhysicalLayer.savePhysicalLayer(physicalLayer, "test/physical_layer.yaml")

end # module TestBaseLayer
