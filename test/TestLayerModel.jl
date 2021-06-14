#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

include("src/LMcore.jl")
import .LMcore
include("src/Console.jl")
import .Console

include("src/BaseLayer.jl")
import .BaseLayer
include("src/NetworkLayer.jl")
import .NetworkLayer
include("src/PhysicalLayer.jl")
import .PhysicalLayer

using Test

module TestLayerModel

@time baseLayer = BaseLayer.load("example_data/layer/0_base.yaml")
@time networkLayer = NetworkLayer.load("example_data/layer/1_network.yaml")
@time physicalLayer = PhysicalLayer.load("example_data/layer/2_physical.yaml")

### test files:
@time networkLayer = NetworkLayer.load("example_data/test/selective_protective_point.yaml")
@time physicalLayer = PhysicalLayer.load("example_data/test/selective_protective_point.yaml")
#
@time networkLayer = NetworkLayer.load("example_data/test/track.yaml")
@time physicalLayer = PhysicalLayer.load("example_data/test/track.yaml")
#
@time networkLayer = NetworkLayer.load("example_data/test/junction1.yaml")
@time physicalLayer = PhysicalLayer.load("example_data/test/junction1.yaml")
#
@time networkLayer = NetworkLayer.load("example_data/test/junction2.yaml")
@time physicalLayer = PhysicalLayer.load("example_data/test/junction2.yaml")
#
@time physicalLayer = PhysicalLayer.load("example_data/snippets/double_crossing.yaml")
@time pathtab = PhysicalLayer.physicalPaths(physicalLayer, ["E1","E2","E3"], ["E4","E5","E6"])
#
@time physicalLayer = PhysicalLayer.load("example_data/snippets/single_slip_turnout.yaml")
@time pathtab = PhysicalLayer.physicalPaths(physicalLayer, ["E1","E2"], ["E3","E4"])

# test function add_junction_paths!
@time NetworkLayer.addJunctionPaths!(physicalLayer,networkLayer)

# test manual user input for the PhysicalLayer
Console.main()

# test function show
@time LMcore.show(baseLayer)
@time LMcore.show(networkLayer)
@time LMcore.show(physicalLayer)

@time BaseLayer.save(baseLayer, "test/base_layer.yaml")
@time PhysicalLayer.save(physicalLayer, "test/physical_layer.yaml")

end # module TestLayerModel
