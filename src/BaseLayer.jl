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

export importBaseLayer, exportBaseLayer, showBaseLayer

# ===========================
"""
Takes a YAML-file and extracts the "network" from it.
Returns a MetaGraph object.
"""
function importBaseLayer(file_path)

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
    MetaGraphs.set_props!(
      network, station,
      Dict(
        :id         =>  data["base_layer"]["stations"][station]["id"],
        :name       =>  data["base_layer"]["stations"][station]["name"],
        :plot_coord => (data["base_layer"]["stations"][station]["plot_coord"])
      )
    )
  end
  # add properties for the links (edges)
  for link in data["base_layer"]["lines"]
    source, target = stationID2Num[link["source"]], stationID2Num[link["target"]]
    LightGraphs.add_edge!(network, source, target)
    MetaGraphs.set_props!(
      network, LightGraphs.Edge(source, target),
      Dict(
        :id    => link["id"],
        :name  => link["name"],
        :start => link["start"],
        :end   => link["end"]
      )
    )
  end

  return network # MetaGraph object

end # function importBaseLayer

# ===========================
"""
Takes a MetaGraph object with a base layer and prints it.
"""
function showBaseLayer(network)

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
function exportBaseLayer(network, file_path)

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

end # function exportBaseLayer

end # module BaseLayer
