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
# @time networkLayer = Main.NetworkLayer.loadNetworkLayer("example_data/layer/1_network.yaml")
# @time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/layer/2_physical.yaml")

### test files:
@time networkLayer = Main.NetworkLayer.loadNetworkLayer("example_data/test/selective_protective_point.yaml")
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/test/selective_protective_point.yaml")
#
@time networkLayer = Main.NetworkLayer.loadNetworkLayer("example_data/test/track.yaml")
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/test/track.yaml")
#
@time networkLayer = Main.NetworkLayer.loadNetworkLayer("example_data/test/junction1.yaml")
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/test/junction1.yaml")
#
@time networkLayer = Main.NetworkLayer.loadNetworkLayer("example_data/test/junction2.yaml")
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/test/junction2.yaml")
#
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/snippets/double_crossing.yaml")
@time distmx = Main.PhysicalLayer.physicalPaths(physicalLayer, ["E1","E2","E3"], ["E4","E5","E6"])
#
@time physicalLayer = Main.PhysicalLayer.loadPhysicalLayer("example_data/snippets/single_slip_turnout.yaml")
@time distmx = Main.PhysicalLayer.physicalPaths(physicalLayer, ["E1","E2"], ["E3","E4"])

# test function add_junction_paths!
@time Main.NetworkLayer.addJunctionPaths!(physicalLayer,networkLayer)

# test function showGraph
@time Main.LMcore.showGraph(baseLayer)
@time Main.LMcore.showGraph(networkLayer)
@time Main.LMcore.showGraph(physicalLayer)

@time Main.BaseLayer.saveBaseLayer(baseLayer, "test/base_layer.yaml")
@time Main.PhysicalLayer.savePhysicalLayer(physicalLayer, "test/physical_layer.yaml")

end # module TestLayerModel
