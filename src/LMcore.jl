#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module LMcore

using YAML
using LightGraphs, MetaGraphs
using GraphPlot

export loadGraph, saveBaseLayer, showBaseLayer

# ===========================
"""
Takes a YAML-file and extracts the "network" from it.
Returns a MetaGraph object.
"""
function loadGraph(file_path, graph_name, node_name, edge_name)

  # load data from external file
  # TODO error handling
  data = YAML.load(open(file_path))

  # determine number of nodes/stations in external file
  numNodes = length(data[graph_name][node_name])
  
  # map node ids to a number
  nodeID2Num = Dict()
  for node in 1:numNodes
    push!(nodeID2Num, data[graph_name][node_name][node]["id"] => node)
  end

  # construct MetaDiGraph with node and edges
  graph = MetaGraphs.MetaDiGraph(numNodes)
  # add generell graph informations
  MetaGraphs.set_prop!(graph, :name, data[graph_name]["name"])

  # add properties for the nodes (vertices)
  for node in 1:numNodes
    node_props = data[graph_name][node_name][node]
    # make sure the station has an id and remove it from the Dict
    MetaGraphs.set_prop!(graph, node, :id, pop!(node_props,"id"))
    # add remaining properties
    for prop in node_props
      MetaGraphs.set_prop!(graph, node, Symbol(prop[1]), prop[2])
    end
  end

  # add properties for the edges
  for edge in data[graph_name][edge_name]
    # make sure the edge has a source and a target and remove them from Dict
    source = nodeID2Num[pop!(edge,"source")]
    target = nodeID2Num[pop!(edge,"target")]
    # adding the edge to the graph
    LightGraphs.add_edge!(graph, source, target)
    # add remaining properties
    for prop in edge
      MetaGraphs.set_prop!(graph, source, target, Symbol(prop[1]), prop[2])
    end
  end

  MetaGraphs.set_indexing_prop!(graph, :id)

  return graph # MetaDiGraph object

end # function loadGraph

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
  push!(data[graph_name], :name => MetaGraphs.get_prop(graph, :name))
  stations = []
  for item in 1:LightGraphs.nv(graph.graph)
    station = Dict()
    for (key,value) in MetaGraphs.props(graph, item)
      push!(station, key => value)
    end
    push!(stations, station)
  end
  push!(data[graph_name], node_name => stations)

  # map station number to an id 
  stationNum2ID = []
  for item in 1:LightGraphs.nv(graph.graph)
    push!(stationNum2ID, MetaGraphs.get_prop(graph, item, :id))
  end

  lines = []
  for item in LightGraphs.edges(graph)
    line = Dict()
    source, target = LightGraphs.src(item), LightGraphs.dst(item)
    push!(line, :source => stationNum2ID[source])
    push!(line, :target => stationNum2ID[target])
    for (key,value) in MetaGraphs.props(graph, source, target)
      push!(line, key => value)
    end
    push!(lines, line)
  end
  push!(data[graph_name], edge_name => lines)

  # TODO error handling
  YAML.write_file(file_path, data)

end # function saveBaseLayer

# ===========================
"""
Takes a MetaGraph object with a base layer and prints it.
"""
function showGraph(graph::AbstractMetaGraph)

  # test if graph has special properties
  graph_has_prop_node_names = !isempty(MetaGraphs.filter_vertices(graph,:name))
  graph_has_prop_edge_names = !isempty(MetaGraphs.filter_edges(graph,:name))
  graph_has_prop_plot_coord = !isempty(MetaGraphs.filter_vertices(graph,:plot_coord))

  nodeNames = []
  for item in 1:LightGraphs.nv(graph.graph)
    if graph_has_prop_node_names
      push!(nodeNames, MetaGraphs.get_prop(graph, item, :name))
    else
      push!(nodeNames, MetaGraphs.get_prop(graph, item, :id))
    end
  end

  edgeNames = []
  for item in LightGraphs.edges(graph)
    source, target = LightGraphs.src(item), LightGraphs.dst(item)
    if graph_has_prop_edge_names
      push!(edgeNames, MetaGraphs.get_prop(graph, source, target, :name))
    else
      push!(edgeNames, MetaGraphs.get_prop(graph, source, target, :id))
    end
  end

  if graph_has_prop_plot_coord
    locs_x = Float64[]
    locs_y = Float64[]
    for item in 1:LightGraphs.nv(graph.graph)
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

end # function showGraph

end # module LMcore
