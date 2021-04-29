#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

include("src/LMcore.jl")

include("src/BaseLayer.jl")
include("src/NetworkLayer.jl")
include("src/PhysicalLayer.jl")

using Test

module TestLayerModel

@time baseLayer = Main.BaseLayer.loadBaseLayer("example_data/layer/0_base.yaml")
@time networkLayer = Main.NetworkLayer.loadNetworkLayer("example_data/layer/1_network.yaml")
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/layer/2_physical.yaml")
@time test = Main.PhysicalLayer.loadPhysicalLayer("example_data/test_rail_path.yaml")

@time Main.LMcore.showGraph(baseLayer)
@time Main.LMcore.showGraph(networkLayer)
@time Main.LMcore.showGraph(physicalLayer)

@time Main.BaseLayer.saveBaseLayer(baseLayer, "test/base_layer.yaml")
@time Main.PhysicalLayer.savePhysicalLayer(physicalLayer, "test/physical_layer.yaml")

end # module TestLayerModel
