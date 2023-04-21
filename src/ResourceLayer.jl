#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module ResourceLayer


include("PhysicalLayer.jl")
import .PhysicalLayer
include("NetworkLayer.jl")
import .NetworkLayer
include("InterlockingLayer.jl")
import .InterlockingLayer

using MetaGraphs, Graphs, YAML, DataFrames

export load

# ===========================
"""
Takes a YAML-file and extracts the Speed Profile Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  return YAML.load(open(file_path))["resource"]

end # function load

"""
Takes a path together with multiple layers and
Returns a DataFrame of Points Of Interest (POI) along the path.
"""
function get_poi(path, networkLayer, resourceLayer, physicalLayer, interlockingLayer)

  network_path = []
  for elem in path
    println(elem)
    edge = NetworkLayer.get_edge(networkLayer, elem[1])
    push!(network_path, (resource = elem[1], link = edge, track = elem[2]))
  end

  if dst(network_path[1][:link]) == src(network_path[2][:link])
    path_direction = "forward"
    direction_factor = 1
    limit_list = :in
  else
    path_direction = "backward"
    limit_list = :out
    direction_factor = -1
  end

  df = DataFrame(Object=String[], Type=String[], NetworkElement=String[], Mileage=Real[], Line=String[])

  for elem in network_path

    println(elem)
    current_path_element, link, track = elem
    current_path_element_pos = first(findall(x -> x[:resource] == current_path_element, network_path))
    if current_path_element_pos != length(network_path)
      next_path_element = network_path[current_path_element_pos+1][:resource]
      next_path_track = network_path[current_path_element_pos+1][:track]
    else
      next_path_element = missing
    end

    network_element  = props(networkLayer, dst(link))[:id]

    # 1.1 link
    link_type = props(networkLayer, link)[:type]
    limit = first(filter(x -> x["track"] == track, props(networkLayer, dst(link))[limit_list]))["limit"]
    link_resources = filter(x -> x["id"] == current_path_element, resourceLayer[link_type * "s"])[1]
    track_segments = filter(x -> x["id"] == track, link_resources["tracks"])[1]["segments"]
    for segment in track_segments
      ## get all berths
      if haskey(segment, "berth")
        for berth in segment["berth"][path_direction]
          name = berth["name"]
          type = "berth"
          pos = PhysicalLayer.get_position(physicalLayer, berth["physical_ref"])
          line = first(pos)["line"]
          mileage = first(pos)["mileage"]
          push!(df, (name, type, current_path_element, mileage, line))
        end
      end
      if path_direction == "forward"
        node = dst(first(MetaGraphs.filter_edges(physicalLayer, :id, last(segment["physical_ref"]))))
      else
        node = src(first(MetaGraphs.filter_edges(physicalLayer, :id, first(segment["physical_ref"]))))
      end
      #
      object_name = MetaGraphs.get_prop(physicalLayer,node, :name)
      if limit["name"] != object_name
        pos = MetaGraphs.get_prop(physicalLayer,node, :pos)
        line = first(pos)["line"]
        mileage = first(pos)["mileage"]
        push!(df, (object_name, "block signal", current_path_element, mileage, line))
        if haskey(segment, "clearing_distance")
          push!(df, (object_name, "block clearing", current_path_element, mileage + direction_factor * segment["clearing_distance"], line))
        end
        if haskey(segment, "breaking_distance")
          mileage = mileage - direction_factor * segment["breaking_distance"]
          push!(df, (object_name, "breaking distance", current_path_element, mileage, line))
          mileage = mileage - direction_factor * 0.3
          push!(df, (object_name, "trigger point", current_path_element, mileage, line))
        end
      end
    end

    # 2. junction network_element
    if !ismissing(next_path_element)
      # 2.1. main signal
      println(limit["name"])
      merge!(limit, first(filter(x -> x["physical_ref"] == limit["physical_ref"], interlockingLayer)))
      pos = PhysicalLayer.get_position(physicalLayer, limit["physical_ref"])
      line = first(pos)["line"]
      mileage = first(pos)["mileage"]
      push!(df, (limit["name"], "main signal", network_element, mileage, line))

      # 2.2. distant signal
      mileage = mileage - direction_factor * limit["breaking_distance"]
      push!(df, (limit["name"], "breaking distance", network_element, mileage, line))
      # 2.3 trigger point
      mileage = mileage - direction_factor * 0.3
      push!(df, (limit["name"], "trigger point", network_element, mileage, line))
      # 2.4. block clearing
      block_clearing = first(filter(x -> x["id"] == "main", limit["overlaps"]))["end"][1]
      type = "block clearing"
      pos = PhysicalLayer.get_position(physicalLayer, block_clearing["physical_ref"])
      line = first(pos)["line"]
      mileage = first(pos)["mileage"]
      push!(df, (limit["name"], type, network_element, mileage, line))
      # 2.5. route clearing
      route_clearing = first(filter(x -> x["target"] == next_path_track, limit["routes"]))["route_clearing"]
      type = "route clearing"
      pos = PhysicalLayer.get_position(physicalLayer, route_clearing["physical_ref"])
      line = first(pos)["line"]
      mileage = first(pos)["mileage"]
      push!(df, (limit["name"], type, network_element, mileage, line))
    end

  end

  return sort!(df, [:Mileage])
end # function get_poi

end #module
