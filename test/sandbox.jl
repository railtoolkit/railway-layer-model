#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

using YAML
using LightGraphs
using GraphPlot
using Colors


# ======================
#function importBaseLayer(file_path)
file_path = "data/network.yaml"

# load data from external file
data = YAML.load(open(file_path))

# determine number of nodes/stations in external file
numStations = length(data["network"]["stations"])

# map station ids to a number and vice versa
stationNum2Names = []
for elem in 1:numStations
  push!(stationNum2Names, data["network"]["stations"][elem]["id"])
end
stationNames2Num = Dict(stationNum2Names[1] => 1) # first element
for elem in 2:numStations # all the other elements
  push!(stationNames2Num, stationNum2Names[elem] => elem)
end

# get plot coords for each station
coord_x = Float64[]
for elem in 1:numStations
  push!(coord_x, data["network"]["stations"][elem]["plot_x_coord"])
end
coord_y = Float64[]
for elem in 1:numStations
  push!(coord_y, data["network"]["stations"][elem]["plot_y_coord"])
end

# determine line connections in external file
connections = []
for link in data["network"]["lines"]
  source = stationNames2Num[link["source"]]
  target = stationNames2Num[link["target"]]
  # for correct sorting and mapping the correct names in the plot
  if source > target # swap
    local tmp = source
    source = target
    target = tmp
  end
  id = link["id"]
  name = link["name"]
  push!(connections, (source, target, name, id))
  end
# sort it by the source for mapping the correct names in the plot
sort!(connections, by = first)
linesNum2Names = []
for link in connections
  push!(linesNum2Names, link[3])
end

# construct graph with station and connections
network = LightGraphs.Graph(numStations)
for link in connections
  LightGraphs.add_edge!(network, link[1], link[2])
end

test = Dict(
  "graph"      => network,
  "nodeNames"  => stationNum2Names,
  "nodeCoords" => (coord_x,coord_y),
  "edgeNames"  => linesNum2Names
)

# ======================
#function showBaseLayer(graph, nodeNames, edgeNames)
graph     = test["graph"]
nodeNames = test["nodeNames"]
edgeNames = test["edgeNames"]
locs_x , locs_y = test["nodeCoords"]

GraphPlot.gplot(
  graph,
  locs_x, locs_y,
  nodelabel=nodeNames,
  NODESIZE=0.05,
  nodelabeldist=1,
  nodelabelangleoffset=4/π,
  edgelabel=edgeNames
)
