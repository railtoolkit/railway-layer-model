#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module PhysicalLayer

include("LMcore.jl")
import .LMcore

using Graphs, MetaGraphs
using DataStructures

export load, save, physicalPaths, get_route_elements

# ===========================
"""
Takes a YAML-file and extracts the Physical Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  graph_name = "physical"
  node_name  = "elements"
  edge_name  = "tracksections"

  graph = LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

  # find switches/crossings and replace "path" with Graphs.Edge and store it in paths
  # include speeds for switches/crossings with branches
  for node in MetaGraphs.filter_vertices(graph, :branches)#
    # replace strings in :relations with Edge object
    paths = Dict{Symbol, Tuple{Graphs.Edge, Graphs.Edge}}()
    speeds = Dict{Symbol, Float64}()
    default_id = 1
    for branch in MetaGraphs.get_prop(graph, node, :branches)
      id = get(branch, "id", string("l",default_id))
      a  = first(MetaGraphs.filter_edges(graph, :id ,branch["path"][1]))
      b  = first(MetaGraphs.filter_edges(graph, :id ,branch["path"][2]))
      push!(paths, Symbol(id) => (a,b))
      speed = get(branch, "speed", Inf)
      if isa(speed,String)
        speed = parse(Float64,speed)
      end
      push!(speeds, Symbol(id) => speed)
      default_id+=1
    end
    MetaGraphs.set_prop!(graph, node, :paths, paths)
    MetaGraphs.set_prop!(graph, node, :speeds, speeds)
    MetaGraphs.rem_prop!(graph, node, :branches)
  end

  return graph

end # function load

# ===========================
"""
Takes a Physical Layer MetaGraph object and converts it to a YAML-file.
"""
function save(graph, file_path)
  # make a copy so that the original graph will not be altered
  physicalLayer = copy(graph)

  graph_name = "physical"
  node_name  = "elements"
  edge_name  = "tracksections"

  # find type branching
  for node in MetaGraphs.filter_vertices(physicalLayer, :paths)
    # replace Edge object in :in and :out with strings
    # println("DEBUG: handling branches for node $node.")
    branches  = []
    for branch in MetaGraphs.get_prop(physicalLayer, node, :paths)
      tmp = Dict()
      branch_id = branch[1]
      branch_path = branch[2]
      # println("DEBUG: \t branch: $branch_path.")
      a = MetaGraphs.get_prop(physicalLayer, branch_path[1], :id)
      b = MetaGraphs.get_prop(physicalLayer, branch_path[2], :id)
      speed = get(MetaGraphs.get_prop(physicalLayer, node, :speeds), branch_id, Inf)
      push!(tmp, "id" => string(branch_id))
      push!(tmp, "path" => [a,b])
      push!(tmp, "speed" => speed)
      push!(branches, tmp)
    end
    MetaGraphs.set_prop!(physicalLayer, node, :branches, branches)
    MetaGraphs.rem_prop!(physicalLayer, node, :paths)
    MetaGraphs.rem_prop!(physicalLayer, node, :speeds)
  end

  for edge in MetaGraphs.filter_edges(physicalLayer, :length)
    length = MetaGraphs.get_prop(physicalLayer, edge, :length)
    length = round(length,digits=4)
    MetaGraphs.set_prop!(physicalLayer, edge, :length, length)
  end

  LMcore.saveGraph(physicalLayer, file_path, graph_name, node_name, edge_name)

end # function save

# ===========================
"""
Takes a physicalLayer with specified in and out nodes.
Returns a Dict (inNode,outNode) => (distance, [sequence of nodes to travel]).
Optional parameter progression with default ":forward".
"""
function physicalPaths(physicalLayer::AbstractMetaGraph, inNodes, outNodes; progression = :forward)
  if progression == :forward
    junction_progression = :in
    junction_progression_reverse = :out
    branch_progression = :out
  else
    junction_progression = :out
    junction_progression_reverse = :in
    branch_progression = :in
  end

  # use junction ID to get connections from NetworkLayer and match them to the PhysicalLayer
  in_nodes  = []
  out_nodes = []
  for node in inNodes
    push!(in_nodes, first(MetaGraphs.filter_vertices(physicalLayer, :id, string(node))))
  end
  for node in outNodes
    push!(out_nodes, first(MetaGraphs.filter_vertices(physicalLayer, :id, string(node))))
  end

  # find shortest path from every in_node
  # TODO: optimize so that already found shortest path can be used with double vertx constraint
  #       e.g. with an adapted Floyd–Warshall algorithm
  # create distance matrix
  pathtab = Dict{Tuple{Int64,Int64}, Tuple{Float64, Vector{Int64}}}()# (inNode,outNode) => (distance, [path])
  #
  while !isempty(in_nodes)
    # println("DEBUG - in_nodes: $in_nodes")
    # init
    Q        = DataStructures.PriorityQueue{Int,Real}()# node_number => distance
    visited  = []
    previous = Dict{Int64, Tuple{Float64,Vector{Int64}}}()# node => distance to start_node, list previous node

    # add starting node to queue
    start_node = popfirst!(in_nodes)
    DataStructures.enqueue!(Q, start_node, 0)
    ### dijkstra: shortest path between nodes from start_node
    while !isempty(Q)
      # println("DEBUG - queue: $Q")
      u,distance = DataStructures.dequeue_pair!(Q)

      # find next node
      if MetaGraphs.get_prop(physicalLayer, u, :type) == "branch" # double vertex graph voodoo
        Main.PhysicalLayer.extend_path_along_relations!(u, physicalLayer, Q, previous, progression)
      elseif (MetaGraphs.get_prop(physicalLayer, u, :type) == "end") & (u != start_node)
        # do not add the next node
      else# node not a branch or end and therefore a single node
        v = Graphs.all_neighbors(physicalLayer.graph, u)[1]
        add_path_to_table!(Graphs.Edge(u,v), distance, physicalLayer, Q, previous)
      end# type testing of nodes

      # update
      push!(visited, u)
      # println("DEBUG - visited: $visited")
      # println("DEBUG - previous: $previous")

    end # while !isempty(Q)

    # take path from out_nodes and save them in the pathtab
    for node in intersect(out_nodes,visited)
      pseq = Int64[]# seqence of nodes from to start_node, previous node
      n = node
      while n != start_node
        pushfirst!(pseq, n)
        if length(previous[n][2]) != 1
          prepend!(pseq, previous[n][2][2:length(previous[n][2])])
        end
        n = first(previous[n][2])
      end
      pushfirst!(pseq, start_node)
      #
      dist = previous[node][1]
      push!(pathtab, (start_node, node) => (dist, pseq))
    end
    # println("DEBUG - pathtab: $pathtab")

  end # while !isempty(in_nodes)

  return pathtab

end # function physicalPaths

# ===========================
"""
Function to call inside physicalPaths().
Needs access to "physicalLayer", "Q", and "previous".
"""
function add_path_to_table!(edge, curr_dist, physicalLayer, Q, previous)
  local u = Graphs.src(edge)
  local v = Graphs.dst(edge)

  distance = Main.PhysicalLayer.graph_distance(physicalLayer, edge, curr_dist)

  Main.PhysicalLayer.update_queue!(Q,v,distance,[u],previous)

end # function add_path_to_table!

"""
Function to call inside physicalPaths().
Needs access to "physicalLayer", "Q", and "previous".
"""
function extend_path_along_relations!(node, physicalLayer, Q, previous_table, progression)
  incoming = Graphs.Edge(last(previous_table[node][2]),node)
  # determine all outgoing egdes
  outgoing = Graphs.Edge[]
  for link in MetaGraphs.get_prop(physicalLayer, node, :link)# find outgoing edge
    if progression == :forward
      if incoming == link[1]
        push!(outgoing, link[2])
      end
    else # progression == :backward
      if incoming == link[2]
        push!(outgoing, link[1])
      end
    end
  end

  # error checking 
  if length(outgoing) == 0
    println("node: $node")
    println("incoming: $incoming")
    links = MetaGraphs.get_prop(physicalLayer, node, :link)
    println("links: $links")
    error("Node $node does not have matching links.")
  end
  
  # update Queue with distances
  curr_dist = previous_table[node][1]
  path = vcat(previous_table[node][2],node)
  delete!(previous_table, node)
  for elem in outgoing
    distance = Main.PhysicalLayer.graph_distance(physicalLayer, elem, curr_dist)

    local u = Graphs.src(incoming)
    local v = Graphs.dst(elem)

    Main.PhysicalLayer.update_queue!(Q,v,distance,path,previous_table)
    
  end
end # function extend_path_along_relations!

"""
Function to call inside "extend_path_along_relations!".
Needs access to "physicalLayer".
"""
function graph_distance(physicalLayer, edge, distance)
  if !isempty(MetaGraphs.filter_edges(physicalLayer,:length))# edge has property "length"
    return distance + MetaGraphs.get_prop(physicalLayer, edge, :length)
  else
    return distance + MetaGraphs.get_prop(physicalLayer, edge, :end) - MetaGraphs.get_prop(physicalLayer, edge, :start)
  end
end # function graph_distance

"""
Function to call inside "extend_path_along_relations!".
Needs access to "previous".
"""
function update_queue!(Q,node,distance,predecessor_list,previous_table)
  if !haskey(previous_table, node)# first visit
    DataStructures.enqueue!(Q, node, distance)
    push!(previous_table, node => (distance, predecessor_list))
  else # node v already in table
    if distance < previous_table[node][1]# new distance must be shorter
      # update previous_table
      push!(previous_table, node => (distance, predecessor_list))
      # update PriorityQueue
      DataStructures.delete!(Q, node)
      DataStructures.enqueue!(Q, node, distance)
    end
  end
end # function update_queue!

"""
Returns all elements of class "branching" and "trap" as a tuple of (name,id) in an array.
"""
function get_route_elements(physicalLayer)
  route_elements = []
  for elem in vertices(physicalLayer)
    attr = props(physicalLayer,elem)
    if attr[:class] == "branching" || attr[:class] == "trap"
        push!(route_elements, (attr[:name],attr[:id]))
    end
  end
  return route_elements
end # getRouteElements

end # module PhysicalLayer