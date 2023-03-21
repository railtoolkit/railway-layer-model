#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module SpeedProfileLayer

using YAML, DataFrames

include("LMcore.jl")

export load, allowanceTable, cutAllowanceTable, joinAllowanceTable, curvatureTable, cutCurvatureTable, joinCurvatureTable, getTrack

# ===========================
"""
Takes a YAML-file and extracts the Speed Profile Layer Attributes.
Returns a MetaGraph object.
"""
function load(file_path)

  return YAML.load(open(file_path))["speed"]

end # function load

# ===========================
"""
Takes a Speed Profile Layer MetaGraph object and converts it to a YAML-file.
"""
function save(speedProfileLayer, file_path)

  #TODO

end # function save

"""
Takes a Dict with speed allowances and converts it to a DataFrame for CSV export
"""
function allowanceTable(speedprofile_layer, id)
  
  track = SpeedProfileLayer.getTrack(speedprofile_layer, id)
  df = DataFrame(Mileage=Real[], Allowance=Union{Missing, Real}[], Track_ID=String[])
  allowance_changes = track["allowance"]
  track_start = track["start"]
  track_end = track["end"]

  first_elem = first(allowance_changes)
  first_mileage = first_elem["pos"][1]["mileage"]
  last_elem = last(allowance_changes)
  last_mileage = last_elem["pos"][1]["mileage"]
  last_allowance = last_elem["vMax"]
  if track_start > first_mileage
      push!(df, (track_start, missing, id))
  end
  for elem in allowance_changes
      mileage = elem["pos"][1]["mileage"]
      allowance = elem["vMax"]
      push!(df, (mileage, allowance, id))
  end
  if track_end >= last_mileage
      push!(df, (track_end, last_allowance, id))
  end

end

function cutAllowanceTable!(df, start_mileage, end_mileage)
  sort!(df, [:Mileage])
  upper = filter(:Mileage => n -> n < start_mileage, df)
  filter!(:Mileage => n -> n >= start_mileage && n <= end_mileage, df)
  if ! isempty(upper)
    upper_allowance = last(upper)[:Allowance]
    upper_id = last(upper)[:Track_ID]
    pushfirst!(df, (start_mileage, upper_allowance, upper_id))
  end
  if ! (last(df)[:Mileage] == end_mileage)
    lower_allowance = last(df)[:Allowance]
    lower_id = last(df)[:Track_ID]
    push!(df, (end_mileage, lower_allowance, lower_id))
  end
end

function joinAllowanceTable(df_in1, df_in2)
  sort!(df_in1, [:Mileage])
  df_in1[!, "Original Mileage"] = df_in1[!,:Mileage]
  sort!(df_in2, [:Mileage])
  df_in2[!, "Original Mileage"] = df_in2[!,:Mileage]
  offset1 = first(df_in2)[:Mileage] - last(df_in1)[:Mileage]
  df_in2[!, :Mileage] = df_in2[!, :Mileage] .- offset1
  df_out = [df_in1;df_in2]
  offset2 = first(df_out)[:Mileage]
  df_out[!, :Mileage] = df_out[!, :Mileage] .- offset2
  return df_out
end

function gradientTable(speedprofile_layer, id)

  gradient_changes = SpeedProfileLayer.getTrack(speedprofile_layer, id)["gradient_changes"]
  df = DataFrame(Mileage=Real[], Slope=Union{Missing, Real}[], Elevation=Union{Missing, Real}[], Track_ID=String[])

  for gradient_change in gradient_changes
      slope = gradient_change["slope"]
      elevation = gradient_change["elevation"]
      mileage = gradient_change["pos"][1]["mileage"]
      push!(df, (mileage, slope, elevation, id))
  end

  return df
end

function cutGradientTable!(df, start_mileage, end_mileage)
  sort!(df, [:Mileage])
  upper = filter(:Mileage => n -> n < start_mileage, df)
  lower = filter(:Mileage => n -> n > end_mileage, df)
  filter!(:Mileage => n -> n >= start_mileage && n <= end_mileage, df)
  if ! isempty(upper)
    first_mileage = first(df)[:Mileage]
    first_elevation = first(df)[:Elevation]
    upper_mileage = last(upper)[:Mileage]
    upper_slope = last(upper)[:Slope]
    upper_elevation = last(upper)[:Elevation]
    upper_id = last(upper)[:Track_ID]
    new_elevation = (first_elevation - upper_elevation) / (first_mileage - upper_mileage) * (start_mileage - upper_mileage) + upper_elevation
    pushfirst!(df, (start_mileage, upper_slope, new_elevation, upper_id))
  end
  if ! isempty(lower)
    last_mileage = last(df)[:Mileage]
    last_elevation = last(df)[:Elevation]
    last_slope = last(df)[:Slope]
    lower_mileage = first(lower)[:Mileage]
    lower_elevation = first(lower)[:Elevation]
    lower_id = first(lower)[:Track_ID]
    new_elevation = (lower_elevation - last_elevation) / (lower_mileage - last_mileage) * (end_mileage - last_mileage) + last_elevation
    push!(df, (end_mileage, last_slope, new_elevation, lower_id))
  end
end

function joinGradientTable(df_in1, df_in2)

  sort!(df_in1, [:Mileage])
  df_in1[!, "Original Mileage"] = df_in1[!,:Mileage]
  sort!(df_in2, [:Mileage])
  df_in2[!, "Original Mileage"] = df_in2[!,:Mileage]
  offset1 = first(df_in2)[:Mileage] - last(df_in1)[:Mileage]
  df_in2[!, :Mileage] = df_in2[!, :Mileage] .- offset1

  # # concat df at mileage
  df_out = [df_in1;df_in2]
  # # set offset to nullify
  offset2 = first(df_out)[:Mileage]
  df_out[!, :Mileage] = df_out[!, :Mileage] .- offset2

  return df_out
end

"""
Takes a Dict with radius_changes and converts it to a DataFrame for CSV export
"""
function curvatureTable(speedprofile_layer, id)

  radius_changes = getTrack(speedprofile_layer, id)["radius_changes"]
  df = DataFrame(Mileage=Real[], Curvature=Union{Missing, Real}[], Class=String[], Track_ID=String[])
  previous_curvature = missing
  previous_class = "transition curve"

  for radius_change in radius_changes

    mileage = radius_change["pos"][1]["mileage"]

    if haskey(radius_change, "radius")
      radius = radius_change["radius"]
      radius isa Number ? nothing : radius = parse(Float64,radius)
      curvature = 1000.0 / radius
    else
      curvature = 0.0 # default
    end

    if radius_change["class"] == "const"
      if curvature == 0
        class = "straight"
      else
        class = "curve"
      end
      if previous_class == "transition curve" || previous_class == class
        push!(df, (mileage, curvature, class, id))
      else
        push!(df, (mileage, previous_curvature, "(stub)", id))
        push!(df, (mileage, curvature, class, id))
      end
    else
      class = "transition curve"
      push!(df, (mileage, previous_curvature, class, id))
    end

    previous_curvature = curvature
    previous_class = class

  end

  return df

end

function cutCurvatureTable!(df, start_mileage, end_mileage)
  sort!(df, [:Mileage])
  upper = filter(:Mileage => n -> n < start_mileage, df)
  filter!(:Mileage => n -> n >= start_mileage && n <= end_mileage, df)
  if ! isempty(upper)
    upper_curvature = last(upper)[:Curvature]
    upper_class = last(upper)[:Class]
    upper_id = last(upper)[:Track_ID]
    pushfirst!(df, (start_mileage, upper_curvature, upper_class, upper_id))
  end
  if ! (last(df)[:Mileage] == end_mileage)
    lower_curvature = last(df)[:Curvature]
    lower_class = last(df)[:Class]
    lower_id = last(df)[:Track_ID]
    push!(df, (end_mileage, lower_curvature, lower_class, lower_id))
  end

end

function joinCurvatureTable(df_in1, df_in2)

  sort!(df_in1, [:Mileage])
  df_in1[!, "Original Mileage"] = df_in1[!,:Mileage]
  sort!(df_in2, [:Mileage])
  df_in2[!, "Original Mileage"] = df_in2[!,:Mileage]
  offset1 = first(df_in2)[:Mileage] - last(df_in1)[:Mileage]
  df_in2[!, :Mileage] = df_in2[!, :Mileage] .- offset1

  # # concat df at mileage
  df_out = [df_in1;df_in2]
  # # set offset to nullify
  offset2 = first(df_out)[:Mileage]
  df_out[!, :Mileage] = df_out[!, :Mileage] .- offset2

  return df_out
  
end

function getTrack(speedprofile_layer, id)
  matching_track = nothing
  for track in speedprofile_layer
      if id == track["id"]
          matching_track = track
          break
      end
  end
  return matching_track
end

end #module
