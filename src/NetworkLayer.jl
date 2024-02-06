#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2024"
# __license__       = "ISC"

module NetworkLayer

include("LMcore.jl")
using Graphs, MetaGraphs

export load, save, addJunctionPaths!, get_link_type

# ===========================
"""
Takes a YAML-file and extracts the Network Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  graph_name = "network"
  node_name  = "junctions"
  edge_name  = "links"

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

function get_edge(networkLayer, id)
  return first(collect(MetaGraphs.filter_edges(networkLayer, :id, id)))
end # function get_link_type

function get_link_type(networkLayer, edge)
  return props(networkLayer, edge)[:type]
end # function get_link_type

function get_next_junction(networkLayer, id, direction)
  edge = first(collect(MetaGraphs.filter_edges(networkLayer, :id, id)))
  if direction == "forward"
    node = dst(edge)
  elseif direction == "backward"
    node = src(edge)
  end
  return props(networkLayer, node)
end # function get_next_junction

function get_next_limit(networkLayer, id, track, direction)
  junction = get_next_junction(networkLayer, id, direction)
  if direction == "forward"
    limits = junction[:in]
  elseif direction == "backward"
    limits = junction[:out]
  end
  return first(filter(x -> x["track"] == track, limits))["limit"]
end # function get_next_limit

end # module NetworkLayer
