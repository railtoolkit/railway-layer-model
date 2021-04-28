#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module NetworkLayer

include("LMcore.jl")

export loadNetworkLayer, saveNetworkLayer

# ===========================
"""
Takes a YAML-file and extracts the Network Layer Attributes.
Returns a MetaGraph object.
"""
function loadNetworkLayer(file_path)

  graph_name = "network"
  node_name  = "nodes"
  edge_name  = "connections"

  return LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

end # function loadNetworkLayer

# ===========================
"""
Takes a Network Layer MetaGraph object and converts it to a YAML-file.
"""
function saveNetworkLayer(networkLayer, file_path)

  graph_name = "network"
  node_name  = "nodes"
  edge_name  = "connections"

  LMcore.saveGraph(networkLayer, file_path, graph_name, node_name, edge_name)

end # function saveNetworkLayer

end # module NetworkLayer
