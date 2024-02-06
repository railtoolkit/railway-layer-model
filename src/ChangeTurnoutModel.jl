#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2024"
# __license__       = "ISC"

module ChangeTurnoutModel

using YAML

function replaceModel!(file_path)

  data = YAML.load(open(file_path))

  graph_name = "physical"
  node_name  = "elements"

  # determine number of nodes/nodes in external file
  nodes = data[graph_name][node_name]

  for node in nodes 
    if node["type"] ∈ ["branch","crossing"]
      tmp = Dict[]
      id = 1
      if node["type"] == "branch"
        in_edges = node["in"]
        out_edges = node["out"]
        delete!(node, "in")
        delete!(node, "out")
        for edge1 in in_edges
          for edge2 in out_edges
            push!(tmp, Dict("path" => [edge1,edge2],"id" => string("branch",id)))
            id+=1
          end
        end
      else
        links = node["link"]
        delete!(node, "link")
        for link in links
          push!(tmp, Dict("path" => [link[1],link[2]],"id" => string("branch",id)))
          id+=1
        end
      end
      push!(node, "type" => "branching")
      push!(node, "branches" => tmp)
    end
  end

  YAML.write_file(file_path, data)

end # function replaceModel!

end # module ChangeTurnoutModel