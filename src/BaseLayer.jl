#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module BaseLayer

using YAML
using LightGraphs, MetaGraphs
using GraphPlot, Colors

export importBaseLayer, showBaseLayer

# ===========================
"""
Takes a YAML-file and extracts the "network" from it.
Returns a MetaGraph object.
"""
function importBaseLayer(file_path)

  # load data from external file
  data = YAML.load(open(file_path))

  # determine number of nodes/stations in external file
  numStations = length(data["network"]["stations"])
  
  # map station ids to a number and vice versa
  stationNum2ID = []
  for station in 1:numStations
    push!(stationNum2ID, data["network"]["stations"][station]["id"])
  end
  stationID2Num = Dict(stationNum2ID[1] => 1) # first station
  for station in 2:numStations # all the other stations
    push!(stationID2Num, stationNum2ID[station] => station)
  end

  # construct SimpleGraph with station and connections
  network = LightGraphs.Graph(numStations)
  # convert SimpleGraph to a MetaGraph
  network = MetaGraphs.MetaGraph(network)
  # add generell graph informations
  MetaGraphs.set_props!(
    network,
    Dict(
      :id   => data["network"]["id"],
      :name => data["network"]["name"]
    )
  )
  # add properties for the stations (vertices)
  for station in 1:numStations
    MetaGraphs.set_props!(
      network,
      station,
      Dict(
        :id         => data["network"]["stations"][station]["id"],
        :name       => data["network"]["stations"][station]["name"],
        :plot_coord => (
          data["network"]["stations"][station]["plot_x_coord"],
          data["network"]["stations"][station]["plot_y_coord"]
        )
      )
    )
  end
  # add properties for the links (edges)
  for link in data["network"]["lines"]
    source = stationID2Num[link["source"]]
    target = stationID2Num[link["target"]]
    # add link to Graph
    LightGraphs.add_edge!(network, source, target)
    #
    MetaGraphs.set_props!(
      network,
      LightGraphs.Edge(source, target),
      Dict(
        :id   => link["id"],
        :name => link["name"]
      )
    )
  end

  return network # MetaGraph object

end # function importBaseLayer

# ===========================
"""
Takes a MetaGraph object with a base layer and prints it.
"""
function showBaseLayer(network::MetaGraph)

  nodeNames = []
  locs_x = Float64[]
  locs_y = Float64[]
  for item in 1:LightGraphs.nv(network.graph)
    push!(nodeNames, MetaGraphs.get_prop(network, item, :name))
    coord_x, coord_y = MetaGraphs.get_prop(network, item, :plot_coord)
    push!(locs_x, coord_x)
    push!(locs_y, coord_y)
  end

  edgeNames = []
  for item in LightGraphs.edges(network)
    source, target = LightGraphs.src(item), LightGraphs.dst(item)
    push!(edgeNames, MetaGraphs.get_prop(network, source, target, :name))
  end

  GraphPlot.gplot(
    network.graph,
    locs_x, locs_y,
    nodelabel=nodeNames,
    NODESIZE=0.05,
    nodelabeldist=1,
    nodelabelangleoffset=4/π,
    edgelabel=edgeNames
  )

end # function showBaseLayer

end # module BaseLayer
