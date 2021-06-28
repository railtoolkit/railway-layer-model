#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module LMtools

using UUIDs
using LightGraphs, MetaGraphs

export posOffset

"""
Change the :pos symbol by an offset.
Offset will be added.
"""
function posOffset(graph::AbstractMetaGraph, offset::AbstractFloat)
  for node in 1:LightGraphs.nv(graph.graph)
    old_pos = MetaGraphs.get_prop(graph, node, :pos)
    MetaGraphs.set_prop!(graph, node, :pos, old_pos + offset)
  end
end # function posOffset


# """
# Add a Location ID to all nodes and edges
# """
# function extendNodeName(graph::AbstractMetaGraph, extension)
#   for node in MetaGraphs.filter_vertices(graph, :name)
#     #TODO
#   end
# end # function extendNodeName


# """
# Takes the IDs of nodes and edges and move them to the name tag.
# Genrates new random IDs base on UUIDs.
# """
# function shiftID2Name(graph::AbstractMetaGraph, extension)
#   for node in MetaGraphs.filter_vertices(graph, :id)
#     #TODO
#   end
# end # function extendNodeName

end # module LMtools