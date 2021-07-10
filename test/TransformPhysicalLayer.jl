#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"


include("src/LMcore.jl")
import .LMcore
include("src/LMtools.jl")
import .LMtools
include("src/PhysicalLayer.jl")
import .PhysicalLayer

module TransformPhysicalLayer

# load PhysicalLayer of operational points (in geo order)
rebenau     = PhysicalLayer.load("example_data/snippets/2_physical_rebenau.yaml")
bk4142      = PhysicalLayer.load("example_data/snippets/2_physical_bk4142.yaml")
pockelsdorf = PhysicalLayer.load("example_data/snippets/2_physical_pockelsdorf.yaml")
bk4748      = PhysicalLayer.load("example_data/snippets/2_physical_bk4748.yaml")
buelten     = PhysicalLayer.load("example_data/snippets/2_physical_buelten.yaml")
schleinitz  = PhysicalLayer.load("example_data/snippets/2_physical_schleinitz.yaml")

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
# PhysicalLayer.save(rebenau, "example_data/snippets/2_physical_rebenau.yaml")
# PhysicalLayer.save(bk4142, "example_data/snippets/2_physical_bk4142.yaml")
# PhysicalLayer.save(pockelsdorf, "example_data/snippets/2_physical_pockelsdorf.yaml")
# PhysicalLayer.save(bk4748, "example_data/snippets/2_physical_bk4748.yaml")
# PhysicalLayer.save(buelten, "example_data/snippets/2_physical_buelten.yaml")
# PhysicalLayer.save(schleinitz, "example_data/snippets/2_physical_schleinitz.yaml")


# level milage to the same of bk4142, bk4748 and pockelsdorf
LMtools.posOffset!(rebenau, -15.739)
LMtools.posOffset!(buelten, -13.2)
LMtools.posOffset!(schleinitz, -13.2)

# connect operational points to a network
physicalLayer = LMcore.newGraph("physical")
LMtools.join!(physicalLayer,rebenau)

LMtools.join!(physicalLayer,bk4142)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "G", "XR"), LMtools.name2ID(physicalLayer, "41", "rebenau_to_pockelsdorf"))
LMtools.set_edge_prop!(physicalLayer, edge, "9724_1", "9724")

LMtools.join!(physicalLayer,pockelsdorf)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "42", "rebenau_to_pockelsdorf"), LMtools.name2ID(physicalLayer, "A", "XPD"))
LMtools.set_edge_prop!(physicalLayer, edge, "9724_2", "9724")

LMtools.join!(physicalLayer,bk4748)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "F", "XPD"), LMtools.name2ID(physicalLayer, "47", "pockelsdorf_to_buelten"))
LMtools.set_edge_prop!(physicalLayer, edge, "9724_3", "9724")

LMtools.join!(physicalLayer,buelten)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "48", "pockelsdorf_to_buelten"), LMtools.name2ID(physicalLayer, "49", "XBU"))
LMtools.set_edge_prop!(physicalLayer, edge, "9724_4", "9724")

LMtools.join!(physicalLayer,schleinitz)
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "20", "XBU"), LMtools.name2ID(physicalLayer, "AA", "XSZ"))
LMtools.set_edge_prop!(physicalLayer, edge, "9721_1", "9721")
edge = LMtools.connect!(physicalLayer, LMtools.name2ID(physicalLayer, "30", "XBU"), LMtools.name2ID(physicalLayer, "A", "XSZ"))
LMtools.set_edge_prop!(physicalLayer, edge, "9721_2", "9721")

# save new graph
PhysicalLayer.save(physicalLayer, "example_data/layer/2_physical.yaml")

end # module TransformPhysicalLayer