#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module NetworkLayer

include("LMcore.jl")
using LightGraphs, MetaGraphs
using DataStructures

export loadNetworkLayer, saveNetworkLayer, add_junction_path!

# ===========================
"""
Takes a YAML-file and extracts the Network Layer Attributes.
Returns a MetaGraph object.
"""
function loadNetworkLayer(file_path)

  graph_name = "network"
  node_name  = "nodes"
  edge_name  = "connections"

  return LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

end # function loadNetworkLayer

# ===========================
"""
Takes a Network Layer MetaGraph object and converts it to a YAML-file.
"""
function saveNetworkLayer(networkLayer, file_path)

  graph_name = "network"
  node_name  = "nodes"
  edge_name  = "connections"

  LMcore.saveGraph(networkLayer, file_path, graph_name, node_name, edge_name)

end # function saveNetworkLayer

# ===========================
"""
Documentation TODO
"""
function add_junction_path!(physicalLayer::AbstractMetaGraph, networkLayer::AbstractMetaGraph; progression = :forward)
  if progression == :forward
    junction_progression = :in
    junction_progression_reverse = :out
    branch_progression = :out
  else
    junction_progression = :out
    junction_progression_reverse = :in
    branch_progression = :in
  end
  # get junction NAME from PhysicalLayer and get junction ID from NetworkLayer
  junction_name = MetaGraphs.get_prop(physicalLayer, :id)
  junction_id   = first(MetaGraphs.filter_vertices(networkLayer, :id, junction_name))

  # use junction ID to get connections from NetworkLayer and match them to the PhysicalLayer
  in_nodes  = []
  out_nodes = []
  for node in MetaGraphs.get_prop(networkLayer, junction_id, junction_progression)
    push!(in_nodes, first(filter_vertices(physicalLayer, :id, string(node))))
  end
  for node in MetaGraphs.get_prop(networkLayer, junction_id, junction_progression_reverse)
    push!(out_nodes, first(filter_vertices(physicalLayer, :id, string(node))))
  end

  # find shortest path from every in_node
  # create distance matrix
  distmx = Dict{Tuple{Int64,Int64}, Tuple{Float64, Vector{Int64}}}()# 
  #
  while !isempty(in_nodes)
    start_node = popfirst!(in_nodes)
    # init
    Q        = DataStructures.PriorityQueue{Int,Real}()# node_number => distance
    visited  = []
    previous = Dict{Int64, Tuple{Float64,Int64}}()# node => distance to start_node, previous node
    # add starting node to queue
    DataStructures.enqueue!(Q, start_node, 0)

    ### dijkstra: shortest path between nodes from start_node
    while !isempty(Q)
      u,distance = DataStructures.dequeue_pair!(Q)

      # find next node
      if MetaGraphs.get_prop(physicalLayer, u, :type) == "branch" # double vertex graph voodoo
        for edge in MetaGraphs.get_prop(physicalLayer, u, branch_progression)
          Main.NetworkLayer.path_update!(edge, distance, physicalLayer, Q, previous)
        end
      elseif MetaGraphs.get_prop(physicalLayer, u, :type) == "crossing" # double vertex graph voodoo
        #TODO
      elseif (MetaGraphs.get_prop(physicalLayer, u, :type) == "end") & (u != start_node)
        # do not add the next node
      else# node not a branch, crossing or end and therefore a single node
        v = LightGraphs.all_neighbors(physicalLayer.graph, u)[1]
        Main.NetworkLayer.path_update!(LightGraphs.Edge(u,v), distance, physicalLayer, Q, previous)
      end# type testing of nodes

      # update
      push!(visited, u)

    end # while !isempty(Q)

    for node in visited
      if node in out_nodes
        dist = previous[node][1]
        pseq = Int64[]# seqence of nodes from to start_node, previous node
        n = node
        while n != start_node
          pushfirst!(pseq, n)
          n = previous[n][2]
        end
        pushfirst!(pseq, start_node)
        push!(distmx, (start_node, node) => (dist, pseq))
      end
    end

  end # while !isempty(in_nodes)

  MetaGraphs.set_prop!(networkLayer, junction_id, :routing, distmx)

end # function add_junction_path!

# ===========================
"""
Function to call inside "add_junction_path!".
Needs access to "physicalLayer", "Q", and "previous".
"""
function path_update!(edge, curr_dist, physicalLayer, Q, previous)
  local u = LightGraphs.src(edge)
  local v = LightGraphs.dst(edge)

  if !isempty(MetaGraphs.filter_edges(physicalLayer,:length))# edge has property "length"
    distance = curr_dist + MetaGraphs.get_prop(physicalLayer, edge, :length)
  else
    distance = curr_dist + MetaGraphs.get_prop(physicalLayer, edge, :end) - MetaGraphs.get_prop(physicalLayer, edge, :start)
  end

  if !haskey(previous, v)# first visit
    DataStructures.enqueue!(Q, v, distance)
    push!(previous, v => (distance, u))
  else # node v already in table
    if distance < previous[v][1]# new distance must be shorter
      # update previous_table
      push!(previous, v => (distance, u))
      # update PriorityQueue
      DataStructures.delete!(Q, v)
      DataStructures.enqueue!(Q, v, distance)
    end
  end

end # function path_update!

end # module NetworkLayer
