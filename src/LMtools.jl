#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module LMtools

using UUIDs
using LightGraphs, MetaGraphs

export posOffset!, addLocationID!, shiftID2Name!, join!, connect!, name2ID, set_edge_prop!

"""
Change the :pos symbol by an offset.
Offset will be added.
"""
function posOffset!(graph::AbstractMetaGraph, offset::AbstractFloat)
  for node in 1:LightGraphs.nv(graph.graph)
    old_pos = MetaGraphs.get_prop(graph, node, :pos)
    MetaGraphs.set_prop!(graph, node, :pos, old_pos + offset)
  end
end # function posOffset!


"""
Add a Location ID to all nodes and edges
"""
function addProp!(graph::AbstractMetaGraph, prop::Symbol, value)
  # nodes
  for node in 1:LightGraphs.nv(graph.graph)
    MetaGraphs.set_prop!(graph, node, prop, value)
  end
  # edges
  for edge in LightGraphs.edges(graph.graph)
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
  for edge in LightGraphs.edges(graph.graph)
    name = MetaGraphs.get_prop(graph, edge, :id)
    MetaGraphs.set_prop!(graph, edge, :name, name)
    MetaGraphs.set_prop!(graph, edge, :id, string(UUIDs.uuid4()))
  end
end # function shiftID2Name!


"""
Merges two MetaGraphs into first MetaGraph
"""
function join!(graph1::AbstractMetaGraph, graph2::AbstractMetaGraph)
  # nodes
  branches = Int[]
  crossings = Int[]
  for node2 in 1:LightGraphs.nv(graph2.graph)
    # add node from graph2 to graph1
    LightGraphs.add_vertex!(graph1)
    node1 = LightGraphs.nv(graph1)
    # transfer the properties
    for (key,value) in MetaGraphs.props(graph2, node2)
      MetaGraphs.set_prop!(graph1, node1, key, value)
    end
    # remember branches and crossings
    if MetaGraphs.get_prop(graph2, node2, :type) == "branch"
      # println("DEBUG: Node(graph2) $node2 as BRANCH handling for Node(graph1) $node1")
      push!(branches, node1)
    elseif MetaGraphs.get_prop(graph2, node2, :type) == "crossing"
      # println("DEBUG: Node(graph2) $node2 as CROSSING handling for Node(graph1) $node1")
      push!(crossings, node1)
    end
  end
  
  # special handling for branches and crossings
  for branch in branches
    in_edges2  = MetaGraphs.get_prop(graph1, branch, :in)
    out_edges2 = MetaGraphs.get_prop(graph1, branch, :out)
    in_edges1 = LightGraphs.Edge[]
    out_edges1 = LightGraphs.Edge[]
    for edge = in_edges2
      source_id2 = MetaGraphs.get_prop(graph2, LightGraphs.src(edge), :id)
      source1 = first(MetaGraphs.filter_vertices(graph1, :id, source_id2))
      push!(in_edges1, LightGraphs.Edge(source1,branch))
    end
    for edge = out_edges2
      target_id2 = MetaGraphs.get_prop(graph2, LightGraphs.dst(edge), :id)
      target1 = first(MetaGraphs.filter_vertices(graph1, :id, target_id2))
      push!(out_edges1, LightGraphs.Edge(branch,target1))
    end
    MetaGraphs.set_prop!(graph1, branch, :in, in_edges1)
    MetaGraphs.set_prop!(graph1, branch, :out, out_edges1)
  end
  for crossing in crossings
    #TODO
    links2 = MetaGraphs.get_prop(graph1, crossing, :link)
    links1 = Tuple{LightGraphs.Edge, LightGraphs.Edge}[]
    for link in links2
      source_id2 = MetaGraphs.get_prop(graph2, LightGraphs.src(link[1]), :id)
      source1 = first(MetaGraphs.filter_vertices(graph1, :id, source_id2))
      target_id2 = MetaGraphs.get_prop(graph2, LightGraphs.dst(link[2]), :id)
      target1 = first(MetaGraphs.filter_vertices(graph1, :id, target_id2))
      a = LightGraphs.Edge(source1,crossing)
      b = LightGraphs.Edge(crossing,target1)
      push!(links1, (a,b))
    end
    MetaGraphs.set_prop!(graph1, crossing, :link, links1)
  end
  
  # edges
  for edge2 in LightGraphs.edges(graph2.graph)
    # add edge  from graph2 to graph1
    source_id2 = MetaGraphs.get_prop(graph2, LightGraphs.src(edge2), :id)
    target_id2 = MetaGraphs.get_prop(graph2, LightGraphs.dst(edge2), :id)
    source1 = first(MetaGraphs.filter_vertices(graph1, :id, source_id2))
    target1 = first(MetaGraphs.filter_vertices(graph1, :id, target_id2))
    LightGraphs.add_edge!(graph1, source1, target1)
    # transfer the properties
    for (key,value) in MetaGraphs.props(graph2, edge2)
      MetaGraphs.set_prop!(graph1, LightGraphs.Edge(source1,target1), key, value)
    end
  end
end # function join!

"""
Connects two node IDs in a graph with an edge
"""
function connect!(graph::AbstractMetaGraph, source_id, target_id)
  source = first(MetaGraphs.filter_vertices(graph, :id, source_id))
  target = first(MetaGraphs.filter_vertices(graph, :id, target_id))
  LightGraphs.add_edge!(graph, source, target)
  return LightGraphs.Edge(source, target)
end

"""
Returns the ID of the node with the name and base_ref.
The combination of name and base_ref must be unique.
"""
function name2ID(graph, name, location_id)
  set1 = MetaGraphs.filter_vertices(graph, :base_ref, location_id)
  set2 = MetaGraphs.filter_vertices(graph, :name, name)
  return MetaGraphs.get_prop(graph, first(intersect(set1,set2)), :id)
end # function name2ID

"""
#TODO
"""
function set_edge_prop!(graph, edge, name, base_ref)
  MetaGraphs.set_prop!(graph, edge, :name, name)
  MetaGraphs.set_prop!(graph, edge, :base_ref, base_ref)
  if !(MetaGraphs.has_prop(graph, edge, :id))
    MetaGraphs.set_prop!(graph, edge, :id, string(UUIDs.uuid4()))
  end
  if !(MetaGraphs.has_prop(graph, edge, :length))
    startKM = MetaGraphs.get_prop(graph, LightGraphs.src(edge), :pos)
    endKM = MetaGraphs.get_prop(graph, LightGraphs.dst(edge), :pos)
    MetaGraphs.set_prop!(graph, edge, :length, endKM - startKM)
  end
end # function set_edge_prop!

end # module LMtools