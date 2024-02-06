#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2024"
# __license__       = "ISC"

module TransformPhysicalLayer

include("../src/LMcore.jl")
import .LMcore
include("../src/LMtools.jl")
import .LMtools
include("../src/PhysicalLayer.jl")
import .PhysicalLayer

using MetaGraphs

# load PhysicalLayer of operational points (in geo order)
rebenau     = PhysicalLayer.load("data/snippets/2_physical_rebenau.yaml")
bk4142      = PhysicalLayer.load("data/snippets/2_physical_bk4142.yaml")
pockelsdorf = PhysicalLayer.load("data/snippets/2_physical_pockelsdorf.yaml")
bk4748      = PhysicalLayer.load("data/snippets/2_physical_bk4748.yaml")
buelten     = PhysicalLayer.load("data/snippets/2_physical_buelten.yaml")
schleinitz  = PhysicalLayer.load("data/snippets/2_physical_schleinitz.yaml")

# # add base_ref IDs from BaseLayer
# LMtools.addProp!(rebenau, :base_ref, "XR")
# LMtools.addProp!(bk4142, :base_ref, "rebenau_to_pockelsdorf")
# LMtools.addProp!(pockelsdorf, :base_ref, "XPD")
# LMtools.addProp!(bk4748, :base_ref, "pockelsdorf_to_buelten")
# LMtools.addProp!(buelten, :base_ref, "XBU")
# LMtools.addProp!(schleinitz, :base_ref, "XSZ")

# # transform IDs
# LMtools.shiftID2Name!(rebenau)
# LMtools.shiftID2Name!(bk4142)
# LMtools.shiftID2Name!(pockelsdorf)
# LMtools.shiftID2Name!(bk4748)
# LMtools.shiftID2Name!(buelten)
# LMtools.shiftID2Name!(schleinitz)

# # save modification
# PhysicalLayer.save(rebenau, "data/snippets/2_physical_rebenau.yaml")
# PhysicalLayer.save(bk4142, "data/snippets/2_physical_bk4142.yaml")
# PhysicalLayer.save(pockelsdorf, "data/snippets/2_physical_pockelsdorf.yaml")
# PhysicalLayer.save(bk4748, "data/snippets/2_physical_bk4748.yaml")
# PhysicalLayer.save(buelten, "data/snippets/2_physical_buelten.yaml")
# PhysicalLayer.save(schleinitz, "data/snippets/2_physical_schleinitz.yaml")


# # level mileage to the same of bk4142, bk4748 and pockelsdorf
# LMtools.posOffset!(rebenau, "9721", -15.739, "9724")
# LMtools.posOffset!(buelten, "9721", -13.2, "9724")
# LMtools.posOffset!(schleinitz, "9721", -13.2, "9724")
# # add mileage to of Mittelstadt to pockelsdorf
# LMtools.posOffset!(pockelsdorf, "9724", -0.1, "9344")

# connect operational points to a network
physicalLayer = LMcore.newGraph("physical")
LMtools.join!(physicalLayer,rebenau)

LMtools.join!(physicalLayer,bk4142)
source_id = LMtools.name2ID(physicalLayer, "G", "XR")
target_id = LMtools.name2ID(physicalLayer, "41", "rebenau_to_pockelsdorf")
name = "9724_1"
edge = LMtools.connect!(physicalLayer, source_id, target_id, name)
MetaGraphs.set_prop!(physicalLayer, edge, :base_ref, "rebenau_to_pockelsdorf")
MetaGraphs.set_prop!(physicalLayer, edge, :network_ref, "XR_XPD")

LMtools.join!(physicalLayer,pockelsdorf)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "42", "rebenau_to_pockelsdorf"), LMtools.name2ID(physicalLayer, "A", "XPD"), "9724_2")
MetaGraphs.set_prop!(physicalLayer, edge, :base_ref, "rebenau_to_pockelsdorf")
MetaGraphs.set_prop!(physicalLayer, edge, :network_ref, "XR_XPD")

LMtools.join!(physicalLayer,bk4748)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "F", "XPD"), LMtools.name2ID(physicalLayer, "47", "pockelsdorf_to_buelten"), "9724_3")

LMtools.join!(physicalLayer,buelten)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "48", "pockelsdorf_to_buelten"), LMtools.name2ID(physicalLayer, "49", "XBU"), "9724_4")
MetaGraphs.set_prop!(physicalLayer, edge, :base_ref, "pockelsdorf_to_buelten")
MetaGraphs.set_prop!(physicalLayer, edge, :network_ref, "XPD_XBU")

LMtools.join!(physicalLayer,schleinitz)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "20", "XBU"), LMtools.name2ID(physicalLayer, "AA", "XSZ"), "9721_1")
MetaGraphs.set_prop!(physicalLayer, edge, :base_ref, "buelten_to_schleinitz")
MetaGraphs.set_prop!(physicalLayer, edge, :network_ref, "XBU_XSZ_1")
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "30", "XBU"), LMtools.name2ID(physicalLayer, "A", "XSZ"), "9721_2")
MetaGraphs.set_prop!(physicalLayer, edge, :base_ref, "buelten_to_schleinitz")
MetaGraphs.set_prop!(physicalLayer, edge, :network_ref, "XBU_XSZ_2")

# save new graph
PhysicalLayer.save(physicalLayer, "data/layers/physical.yaml")

end # module TransformPhysicalLayer