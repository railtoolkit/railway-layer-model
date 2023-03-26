#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module InterlockingLayer

using YAML, DataFrames, MetaGraphs, Graphs

export load, getRouteElements

# ===========================
"""
Takes a YAML-file and extracts the Speed Profile Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  return YAML.load(open(file_path))["interlocking"]

end # function load

function selectLimit!(layer, interlocking_id)
  filter!(x -> x["network_ref"] == interlocking_id, layer)
end

function get_route_table(interlockingLayer, interlocking_elements)
  # interlocking_elements = PhysicalLayer.get_route_elements(physicalLayer)
  df = DataFrame(Limit=String[], Target=Union{Missing,String}[], Type=String[], Name=String[], Elements=Array[])
  elemID2Num = Dict()
  for elem in eachindex(interlocking_elements)
    push!(elemID2Num, interlocking_elements[elem][2] => elem)
  end
  for signal in interlockingLayer
    limit = signal["entrance_name"]
    for route in signal["routes"]
      route_elem = Array{Union{Missing, Array{String}}}(missing, length(interlocking_elements))
      target = route["target"]
      name = route["id"]

      for elem in route["en_route"]
        elem_number = elemID2Num[elem["physical_ref"]]
        route_elem[elem_number] = [elem["branch"]]
      end
      for elem in route["flankprotection"]["turnouts"]
        elem_number = elemID2Num[elem["physical_ref"]]
        route_elem[elem_number] = elem["branches"]
      end

      push!(df, (limit, target, "route", name, route_elem))
    end
    for overlap in signal["overlaps"]
        overlap_elem = Array{Union{Missing, Array{String}}}(missing, length(interlocking_elements))
        name = overlap["id"]
        if haskey(overlap, "en_route")
          for elem in overlap["en_route"]
            elem_number = elemID2Num[elem["physical_ref"]]
            overlap_elem[elem_number] = [elem["branch"]]
          end
        end
        if haskey(overlap, "flankprotection")
          for elem in overlap["flankprotection"]["turnouts"]
            elem_number = elemID2Num[elem["physical_ref"]]
            overlap_elem[elem_number] = elem["branches"]
          end
        end
        push!(df, (limit, signal["network_ref"], "overlap", name, overlap_elem))
    end
  end

  elements = df[!,:Elements]
  for item in interlocking_elements
    pos = elemID2Num[item[2]]
    tmp = Array{Union{Missing, Array{String}}}(missing, length(elements))
    idx = 1
    for elem in elements
      tmp[idx] = elem[pos]
      idx += 1
    end
    df[:, Symbol(item[1])] = tmp
  end
  select!(df, Not(:Elements))

  return df

end # function get_route_table


function get_route_conflicts(route_table, interlocking_elements)

  ## private  functions
  same_start(route1, route2)     = route1[:Limit] == route2[:Limit]
  different_type(route1, route2) = route1[:Type]  != route2[:Type]
  same_route(route1, route2)     = same_start(route1, route2) && route1[:Target] == route2[:Target] && route1[:Name] == route2[:Name]
  route_name(route) = route[:Limit] * "-" * route[:Target] * "-" * route[:Name]
  function route_element_conflict(route1, route2, interlocking_elements)
    result = false
    for elem in interlocking_elements
      if ! ismissing(route1[Symbol(elem[1])]) && ! ismissing(route2[Symbol(elem[1])])
        res1 = route1[Symbol(elem[1])]
        res2 = route2[Symbol(elem[1])]
  
        test = []
        for res in res1
          push!(test,res ∉ res2)
        end
        false ∉ test ? result = true : nothing
        # println("Element $elem result: $result")
      end
    end
    return result
  end

  ## init
  matrix = DataFrame(Route=String[])
  for route in Tables.rowtable(route_table)
    matrix[!, route_name(route)] = Union{Missing,Bool}[]
  end

  for route1 in Tables.rowtable(route_table)
    new_row = Dict()
    push!(new_row, :Route => route_name(route1))
    for route2 in Tables.rowtable(route_table)
      entry = false # default
      if same_route(route1, route2)
        entry = missing
      elseif same_start(route1, route2) 
        if different_type(route1, route2)
          # println("checking route conflict with same start")
          route_element_conflict(route1, route2, interlocking_elements) ? nothing : entry = true
        else
          entry = true
        end
      else
        # println("checking route conflict with different start")
        route_element_conflict(route1, route2, interlocking_elements) ? nothing : entry = true
      end
      key = route_name(route2)
      push!(new_row, Symbol(key) => entry)
    end
    push!(matrix, new_row)
  end

  return matrix

end # function get_route_conflicts

end #module
