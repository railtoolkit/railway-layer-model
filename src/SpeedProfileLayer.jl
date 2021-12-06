#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module SpeedProfileLayer

include("LMcore.jl")

export load, save

# ===========================
"""
Takes a YAML-file and extracts the Speed Profile Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  graph_name = "speedprofile"
  node_name  = "segment"
  edge_name  = "charactersection"

  return LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

end # function load

# ===========================
"""
Takes a Speed Profile Layer MetaGraph object and converts it to a YAML-file.
"""
function save(speedProfileLayer, file_path)

  graph_name = "speedprofile"
  node_name  = "segment"
  edge_name  = "charactersection"

  LMcore.saveGraph(speedProfileLayer, file_path, graph_name, node_name, edge_name)

end # function save

function runtime()

  #TODO

end # function runtime

function staticSpeedProfile()

  # TODO

end

function dynamicSpeedProfile()

  # TODO

end

end # module SpeedProfileLayer
