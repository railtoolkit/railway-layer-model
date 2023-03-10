#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module TestSpeedInformatiion
#
## collect characteristic sections for a given path
# path to investigate:
start = ("XSZ_3", "H3_1")
destination = ("XR_4", "H4_1")

# get base from start and destination

# find path in base layer

# find path in network layer

# init empty dict

#direction = get direction from physical node
#pos = get pos  from physical node
#check speed an gradient from speed layer


baseLayer = BaseLayer.load("example_data/layer/0_base.yaml")
networkLayer = NetworkLayer.load("example_data/layer/1_network.yaml")

physicalLayer = PhysicalLayer.load("example_data/snippets/double_crossing.yaml")
pathtab = PhysicalLayer.physicalPaths(physicalLayer, ["E1","E2","E3"], ["E4","E5","E6"])

end # module TestSpeedInformatiion
