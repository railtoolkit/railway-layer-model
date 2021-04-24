#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module PhysicalLayer

include("LMcore.jl")
using LightGraphs, MetaGraphs

export loadPhysicalLayer, savePhysicalLayer

# ===========================
"""
Takes a YAML-file and extracts the Physical Layer Attributes.
Returns a MetaGraph object.
"""
function loadPhysicalLayer(file_path)
  file_path = "data/physical_layer.yaml"

  graph_name = "physical_layer"
  node_name  = "elements"
  edge_name  = "tracks"

  graph = LMcore.loadGraph(file_path, graph_name, node_name, edge_name)

  for node in filter_vertices(graph, :forward)# or :backward
    # replace strings in :forward and :backward with Edge object
    for symbol in [:forward,:backward]
      tmp  = LightGraphs.Edge[]
      for edge in MetaGraphs.get_prop(graph, node, symbol)
        push!(tmp, first(MetaGraphs.filter_edges(graph, :id ,edge)))
      end
      MetaGraphs.set_prop!(graph, node, symbol, tmp)
    end
  end

  return graph

end # function loadPhysicalLayer

# ===========================
"""
Takes a Physical Layer MetaGraph object and converts it to a YAML-file.
"""
function savePhysicalLayer(graph, file_path)
  # make a copy so that the original graph will not be altered
  physicalLayer = copy(graph)

  graph_name = "physical_layer"
  node_name  = "elements"
  edge_name  = "tracks"

  for node in filter_vertices(physicalLayer, :forward)# or :backward
    # replace Edge object in :forward and :backward with strings
    for symbol in [:forward,:backward]
      tmp  = []
      for edge in MetaGraphs.get_prop(physicalLayer, node, symbol)
        push!(tmp, MetaGraphs.get_prop(physicalLayer, edge, :id))
      end
      MetaGraphs.set_prop!(physicalLayer, node, symbol, tmp)
    end
  end

  LMcore.saveGraph(physicalLayer, file_path, graph_name, node_name, edge_name)

end # function saveBaseLayer

end # module PhysicalLayer