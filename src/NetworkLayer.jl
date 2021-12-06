#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module NetworkLayer

include("LMcore.jl")
using Graphs, MetaGraphs

export load, save, addJunctionPaths!

# ===========================
"""
Takes a YAML-file and extracts the Network Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  graph_name = "network"
  node_name  = "nodes"
  edge_name  = "connections"

  return LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

end # function load

# ===========================
"""
Takes a Network Layer MetaGraph object and converts it to a YAML-file.
"""
function save(networkLayer, file_path)

  graph_name = "network"
  node_name  = "nodes"
  edge_name  = "connections"

  LMcore.saveGraph(networkLayer, file_path, graph_name, node_name, edge_name)

end # function save

# ===========================
"""
Adds a Dict with path to junction based on the physical layer.
"""
function addJunctionPaths!(physicalLayer::AbstractMetaGraph, networkLayer::AbstractMetaGraph; progression = :forward)
  if progression == :forward
    junction_progression = :in
    junction_progression_reverse = :out
  else
    junction_progression = :out
    junction_progression_reverse = :in
  end
  # get junction NAME from PhysicalLayer and get junction ID from NetworkLayer
  junction_name = MetaGraphs.get_prop(physicalLayer, :id)
  junction_id   = first(MetaGraphs.filter_vertices(networkLayer, :id, junction_name))

  # use junction ID to get connections from NetworkLayer and match them to the PhysicalLayer
  inNodes = MetaGraphs.get_prop(networkLayer, junction_id, junction_progression)
  outNodes = MetaGraphs.get_prop(networkLayer, junction_id, junction_progression_reverse)

  pathtab = Main.PhysicalLayer.physicalPaths(physicalLayer, inNodes, outNodes, progression)

  MetaGraphs.set_prop!(networkLayer, junction_id, :paths, pathtab)

end # function addJunctionPaths!

end # module NetworkLayer
