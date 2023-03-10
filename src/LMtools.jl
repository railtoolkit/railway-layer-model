#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module LMtools

using UUIDs
using Graphs, MetaGraphs

export posOffset!, addLocationID!, shiftID2Name!, join!, connect!, name2ID, set_edge_prop!

"""
Change the :pos symbol by an offset.
Offset will be added.
"""
function posOffset!(graph::AbstractMetaGraph, old_line::String, offset::AbstractFloat, new_line::String)
  for node in 1:Graphs.nv(graph.graph)
    pos = MetaGraphs.get_prop(graph, node, :pos) # get pointer to pos
    new_pos = pos[old_line] + offset
    new_pos = round(new_pos,digits=6)
    push!(pos, new_line => new_pos)
  end
end # function posOffset!


"""
Add a Location ID to all nodes and edges
"""
function addProp!(graph::AbstractMetaGraph, prop::Symbol, value)
  # nodes
  for node in 1:Graphs.nv(graph.graph)
    MetaGraphs.set_prop!(graph, node, prop, value)
  end
  # edges
  for edge in Graphs.edges(graph.graph)
    MetaGraphs.set_prop!(graph, edge, prop, value)
  end
end # function addLocationID!


"""
Takes the IDs of nodes and edges and move them to the name tag.
Genrates new random IDs base on UUIDs.
"""
function shiftID2Name!(graph::AbstractMetaGraph)
  # nodes
  for node in MetaGraphs.filter_vertices(graph, :id)
    name = MetaGraphs.get_prop(graph, node, :id)
    MetaGraphs.set_prop!(graph, node, :name, name)
    MetaGraphs.set_prop!(graph, node, :id, string(UUIDs.uuid4()))
  end
  # edges
  for edge in Graphs.edges(graph.graph)
    name = MetaGraphs.get_prop(graph, edge, :id)
    MetaGraphs.set_prop!(graph, edge, :name, name)
    MetaGraphs.set_prop!(graph, edge, :id, string(UUIDs.uuid4()))
  end
end # function shiftID2Name!


"""
Merges two MetaGraphs into first MetaGraph
Can also handle PhysicalLayer with branches
"""
function join!(graph1::AbstractMetaGraph, graph2::AbstractMetaGraph)
  #####
  # 1. match all (a) nodes and (b) edges from graph2 into graph1
  # 2. special handling for branches to modify the properties in the nodes to the new IDs
  #####
  #
  branches = Int[] # remember nodes with type = "branching" for 2.
  # 1(a) nodes
  for node2 in 1:Graphs.nv(graph2.graph)
    # add node from graph2 to graph1
    Graphs.add_vertex!(graph1)
    node1 = Graphs.nv(graph1) # remember new node number
    # transfer all node properties from graph2 to graph1
    for (key,value) in MetaGraphs.props(graph2, node2)
      MetaGraphs.set_prop!(graph1, node1, key, value)
    end
    # remember nodes with type = "branching" for 2.
    if MetaGraphs.get_prop(graph2, node2, :type) == "branching"
      # println("DEBUG: Node(graph2) $node2 as BRANCH handling for Node(graph1) $node1")
      push!(branches, node1)
    end
  end
  #
  # 1(b) edges
  for edge2 in Graphs.edges(graph2.graph)
    # add edge from graph2 to graph1
    # get and search for src and dst through node-ID
    source_id2 = MetaGraphs.get_prop(graph2, Graphs.src(edge2), :id)
    target_id2 = MetaGraphs.get_prop(graph2, Graphs.dst(edge2), :id)
    source1 = first(MetaGraphs.filter_vertices(graph1, :id, source_id2))
    target1 = first(MetaGraphs.filter_vertices(graph1, :id, target_id2))
    #
    Graphs.add_edge!(graph1, source1, target1)
    # transfer the properties
    for (key,value) in MetaGraphs.props(graph2, edge2)
      MetaGraphs.set_prop!(graph1, Graphs.Edge(source1,target1), key, value)
    end
  end
  #
  # 2. special handling for nodes with type = "branching"
  for branch in branches
    paths2 = MetaGraphs.get_prop(graph1, branch, :paths)
    paths1 = Dict{Symbol, Tuple{Graphs.Edge, Graphs.Edge}}()
    for path in keys(paths2)
      source_id2 = MetaGraphs.get_prop(graph2, Graphs.src(paths2[path][1]), :id)
      source1 = first(MetaGraphs.filter_vertices(graph1, :id, source_id2))
      target_id2 = MetaGraphs.get_prop(graph2, Graphs.dst(paths2[path][2]), :id)
      target1 = first(MetaGraphs.filter_vertices(graph1, :id, target_id2))
      a = Graphs.Edge(source1,branch)
      b = Graphs.Edge(branch,target1)
      push!(paths1, path => (a,b))
    end
    MetaGraphs.set_prop!(graph1, branch, :paths, paths1)
  end
  #
end # function join!

"""
Connects two node IDs in a graph with an edge
and generats basic properties
"""
function connect!(graph::AbstractMetaGraph, source_id, target_id, name)
  # add connecting edge to graph
  source = first(MetaGraphs.filter_vertices(graph, :id, source_id))
  target = first(MetaGraphs.filter_vertices(graph, :id, target_id))
  Graphs.add_edge!(graph, source, target)
  #
  edge = Graphs.Edge(source, target)
  #
  # set name
  MetaGraphs.set_prop!(graph, edge, :name, name)
  #
  # generate ID
  MetaGraphs.set_prop!(graph, edge, :id, string(UUIDs.uuid4()))
  #
  # calculate length
  source = Graphs.src(edge)
  source_pos = get_prop(graph, source, :pos)
  destination = Graphs.dst(edge)
  destination_pos = get_prop(graph, destination, :pos)
  # find common line between src and dst
  common_line = first(intersect(keys(source_pos),keys(destination_pos)))
  # get mileage
  startKM = source_pos[common_line]
  endKM = destination_pos[common_line]
  # set length
  MetaGraphs.set_prop!(graph, edge, :length, endKM - startKM)
  #
  return edge
end # function connect!

"""
Returns the ID of the node with the name and base_ref.
The combination of name and base_ref must be unique.
"""
function name2ID(graph, name, location_id)
  set1 = MetaGraphs.filter_vertices(graph, :base_ref, location_id)
  set2 = MetaGraphs.filter_vertices(graph, :name, name)
  return MetaGraphs.get_prop(graph, first(intersect(set1,set2)), :id)
end # function name2ID

end # module LMtools