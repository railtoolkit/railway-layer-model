#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module LMcore

using YAML
using Graphs, MetaGraphs
using LinearAlgebra
using GraphPlot

export loadGraph, newGraph, saveGraph, show, distance_type, has_edge, has_node

# ===========================
"""
Takes a YAML-file and extracts the "network" from it.
Returns a MetaGraph object.
"""
function loadGraph(file_path, graph_name, node_name, edge_name)

  # load data from external file
  # TODO error handling
  data = YAML.load(open(file_path))

  # determine number of nodes/nodes in external file
  numNodes = length(data[graph_name][node_name])
  
  # map node ids to a number
  nodeID2Num = Dict()
  for node in 1:numNodes
    push!(nodeID2Num, data[graph_name][node_name][node]["id"] => node)
  end

  # construct MetaDiGraph with node and edges
  graph = MetaGraphs.MetaDiGraph(numNodes)
  MetaGraphs.defaultweight!(graph, NaN)
  # add generell graph informations
  if haskey(data[graph_name], "name") && (typeof(data[graph_name]["name"]) != Nothing)
    MetaGraphs.set_prop!(graph, :name, data[graph_name]["name"])
  end
  if haskey(data[graph_name], "id") && (typeof(data[graph_name]["id"]) != Nothing)
    MetaGraphs.set_prop!(graph, :id, data[graph_name]["id"])
  end

  # add properties for the nodes (vertices)
  for node in 1:numNodes
    node_props = data[graph_name][node_name][node]
    # make sure the node has an id and remove it from the Dict
    MetaGraphs.set_prop!(graph, node, :id, pop!(node_props,"id"))
    # add remaining properties
    for prop in node_props
      MetaGraphs.set_prop!(graph, node, Symbol(prop[1]), prop[2])
    end
  end

  # create distance matrix
  #distmx = zeros(numNodes,numNodes)
  distmx =  Array{Union{Missing, Float64}}(missing, numNodes, numNodes)
  # diagonal with zeros
  distmx[LinearAlgebra.diagind(distmx)] .= 0.0

  # add properties for the edges
  if haskey(data[graph_name], edge_name) & (typeof(data[graph_name][edge_name]) != Nothing)
    for edge in data[graph_name][edge_name]
      # make sure the edge has a source and a target and remove them from Dict
      source = nodeID2Num[pop!(edge,"source")]
      target = nodeID2Num[pop!(edge,"target")]
      # adding the edge to the graph
      Graphs.add_edge!(graph.graph, source, target)
      # add remaining properties
      for prop in edge
        MetaGraphs.set_prop!(graph, source, target, Symbol(prop[1]), prop[2])
      end
      # add distance to weight field if hast "start" and "end"
      if haskey(edge, "start") & haskey(edge, "end")
        if edge["start"] < edge["end"]
          distance = edge["end"] - edge["start"]
        else
          distance = edge["start"] - edge["end"]
        end
        distmx[source,target] = distmx[target,source] = distance
      elseif haskey(edge, "length")
        distmx[source,target] = distmx[target,source] = edge["length"]
      end
    end
  end

  MetaGraphs.set_prop!(graph, :distances, distmx)
  MetaGraphs.weightfield!(graph, :distances)
  MetaGraphs.set_indexing_prop!(graph, :id)

  return graph # MetaDiGraph object

end # function loadGraph

# ===========================
"""
Creates an empty MetaGraph object and returns it.
"""
function newGraph(graph_id, numNodes = 0 )
  graph = MetaGraphs.MetaDiGraph(numNodes)
  MetaGraphs.defaultweight!(graph, NaN)

  # create distance matrix
  #distmx = zeros(numNodes,numNodes)
  distmx =  Array{Union{Missing, Float64}}(missing, numNodes, numNodes)
  # diagonal with zeros
  distmx[LinearAlgebra.diagind(distmx)] .= 0.0

  MetaGraphs.set_prop!(graph, :distances, distmx)
  MetaGraphs.weightfield!(graph, :distances)
  MetaGraphs.set_prop!(graph, :id, graph_id)
  MetaGraphs.set_indexing_prop!(graph, :id)

  return graph # MetaDiGraph object

end # function newGraph

# ===========================
"""
Takes a MetaGraph object and converts it to a YAML-file.
"""
function saveGraph(graph::AbstractMetaGraph, file_path, graph_name, node_name, edge_name)
  graph_name = Symbol(graph_name)
  node_name  = Symbol(node_name)
  edge_name  = Symbol(edge_name)

  data = Dict()
  push!(data, graph_name => Dict())
  if MetaGraphs.has_prop(graph, :name)
    push!(data[graph_name], :name => MetaGraphs.get_prop(graph, :name))
  end

  nodes = []
  for item in 1:Graphs.nv(graph.graph)
    node = Dict()
    for (key,value) in MetaGraphs.props(graph, item)
      push!(node, key => value)
    end
    push!(nodes, node)
  end
  push!(data[graph_name], node_name => nodes)

  # map node number to an id 
  nodeNum2ID = []
  for item in 1:Graphs.nv(graph.graph)
    push!(nodeNum2ID, MetaGraphs.get_prop(graph, item, :id))
  end

  relations = []
  for item in Graphs.edges(graph)
    relation = Dict()
    source, target = Graphs.src(item), Graphs.dst(item)
    push!(relation, :source => nodeNum2ID[source])
    push!(relation, :target => nodeNum2ID[target])
    for (key,value) in MetaGraphs.props(graph, source, target)
      push!(relation, key => value)
    end
    push!(relations, relation)
  end
  push!(data[graph_name], edge_name => relations)

  # TODO error handling
  YAML.write_file(file_path, data)

end # function save

# ===========================
"""
Takes a MetaGraph object with a base layer and prints it.
"""
function show(graph::AbstractMetaGraph)

  # test if graph has special properties
  graph_has_prop_node_names = !isempty(MetaGraphs.filter_vertices(graph,:name))
  graph_has_prop_edge_names = !isempty(MetaGraphs.filter_edges(graph,:name))
  graph_has_prop_plot_coord = !isempty(MetaGraphs.filter_vertices(graph,:plot_coord))

  nodeNames = []
  for item in 1:Graphs.nv(graph.graph)
    if graph_has_prop_node_names
      push!(nodeNames, MetaGraphs.get_prop(graph, item, :name))
    else
      push!(nodeNames, MetaGraphs.get_prop(graph, item, :id))
    end
  end

  edgeNames = []
  for item in Graphs.edges(graph)
    source, target = Graphs.src(item), Graphs.dst(item)
    if graph_has_prop_edge_names
      push!(edgeNames, MetaGraphs.get_prop(graph, source, target, :name))
    else
      push!(edgeNames, MetaGraphs.get_prop(graph, source, target, :id))
    end
  end

  if graph_has_prop_plot_coord
    locs_x = Float64[]
    locs_y = Float64[]
    for item in 1:Graphs.nv(graph.graph)
      coord_x, coord_y = MetaGraphs.get_prop(graph, item, :plot_coord)
      push!(locs_x, coord_x)
      push!(locs_y, coord_y)
    end

    GraphPlot.gplot(
      graph.graph,
      locs_x, locs_y,
      nodelabel=nodeNames,
      NODESIZE=0.05,
      nodelabeldist=1,
      nodelabelangleoffset=4/π,
      edgelabel=edgeNames
    )
    
  else

    GraphPlot.gplot(
      graph.graph,
      nodelabel=nodeNames,
      NODESIZE=0.05,
      nodelabeldist=1,
      nodelabelangleoffset=4/π,
      edgelabel=edgeNames
    )

  end

end # function show

"""
Function to make sure that nodes are ordered.
Enables distance matrix to be symetric.
"""
function distance_type(node1,node2,distance)
  if node2 > node1
    return Dict((node1,node2) => distance)
  else
    return Dict((node2,node1) => distance)
  end
end # function distance_type

function has_node(graph, node_id)::Bool
  return !(length(collect(MetaGraphs.filter_vertices(graph, :id, node_id))) == 0)
end # function has_node

function has_edge(graph, edge_id)::Bool
  return !(length(collect(MetaGraphs.filter_edges(graph, :id, edge_id))) == 0)
end # function has_edge

end # module LMcore
