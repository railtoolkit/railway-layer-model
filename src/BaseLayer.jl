#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module BaseLayer

include("LMcore.jl")

export loadBaseLayer, saveBaseLayer

# ===========================
"""
Takes a YAML-file and extracts the Base Layer Attributes.
Returns a MetaGraph object.
"""
function loadBaseLayer(file_path)

  graph_name = "base"
  node_name  = "stations"
  edge_name  = "lines"

  return LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

end # function loadBaseLayer

# ===========================
"""
Takes a Base Layer MetaGraph object and converts it to a YAML-file.
"""
function saveBaseLayer(baseLayer, file_path)

  graph_name = "base"
  node_name  = "stations"
  edge_name  = "lines"

  LMcore.saveGraph(baseLayer, file_path, graph_name, node_name, edge_name)

end # function saveBaseLayer

end # module BaseLayer
