#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module BaseLayer

using YAML
using LightGraphs, MetaGraphs
using GraphPlot

export loadBaseLayer, saveBaseLayer, showBaseLayer

# ===========================
"""
Takes a YAML-file and extracts the "network" from it.
Returns a MetaGraph object.
"""
function loadBaseLayer(file_path)

  # load data from external file
  # TODO error handling
  data = YAML.load(open(file_path))

  # determine number of nodes/stations in external file
  numStations = length(data["base_layer"]["stations"])
  
  # map station ids to a number
  stationID2Num = Dict()
  for station in 1:numStations
    push!(stationID2Num, data["base_layer"]["stations"][station]["id"] => station)
  end

  # construct MetaDiGraph with station and connections
  network = MetaGraphs.MetaDiGraph(numStations)
  # add generell graph informations
  MetaGraphs.set_prop!(network, :name, data["base_layer"]["name"])

  # add properties for the stations (vertices)
  for station in 1:numStations
    station_props = data["base_layer"]["stations"][station]
    # make sure the station has an id and remove it from the Dict
    MetaGraphs.set_prop!( network, station, :id, pop!(station_props,"id"))
    # add remaining properties
    for station_prop in station_props
      MetaGraphs.set_prop!(network, station, Symbol(station_prop[1]), station_prop[2])
    end
  end

  # add properties for the links (edges)
  for link in data["base_layer"]["lines"]
    # make sure the link has a source and a target and remove them from Dict
    source = stationID2Num[pop!(link,"source")]
    target = stationID2Num[pop!(link,"target")]
    # adding the link to the graph
    LightGraphs.add_edge!(network, source, target)
    # add remaining properties
    for link_prop in link
      MetaGraphs.set_prop!(network, source, target, Symbol(link_prop[1]), link_prop[2])
    end
  end

  return network # MetaDiGraph object

end # function loadBaseLayer

# ===========================
"""
Takes a MetaGraph object with a base layer and prints it.
"""
function showBaseLayer(network::AbstractMetaGraph)

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

# ===========================
"""
Takes a MetaGraph object and converts it to a YAML-file.
"""
function saveBaseLayer(network::AbstractMetaGraph, file_path)

  data = Dict()
  push!(data, :base_layer => Dict())
  push!(data[:base_layer], :name => MetaGraphs.get_prop(network, :name))
  stations = []
  for item in 1:LightGraphs.nv(network.graph)
    station = Dict()
    for (key,value) in MetaGraphs.props(network, item)
      push!(station, key => value)
    end
    push!(stations, station)
  end
  push!(data[:base_layer], :stations => stations)

  # map station number to an id 
  stationNum2ID = []
  for item in 1:LightGraphs.nv(network.graph)
    push!(stationNum2ID, MetaGraphs.get_prop(network, item, :id))
  end

  lines = []
  for item in LightGraphs.edges(network)
    line = Dict()
    source, target = LightGraphs.src(item), LightGraphs.dst(item)
    push!(line, :source => stationNum2ID[source])
    push!(line, :target => stationNum2ID[target])
    for (key,value) in MetaGraphs.props(network, source, target)
      push!(line, key => value)
    end
    push!(lines, line)
  end
  push!(data[:base_layer], :lines => lines)

  # TODO error handling
  YAML.write_file(file_path, data)

end # function saveBaseLayer

end # module BaseLayer
