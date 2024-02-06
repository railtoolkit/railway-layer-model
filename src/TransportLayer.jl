#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2024"
# __license__       = "ISC"

module TransportLayer

include("LMcore.jl")
import .LMcore
include("TransitLayer.jl")
import .TransitLayer

using DataFrames, UUIDs
using Makie, Makie.GeometryBasics, CairoMakie # packages for plotting

export getBlockingTimesFromSnippets, minimumHeadway, dwellTime, svtPlot, addTrain!

"""
returns a DataFrame with (s,t,vs,vt) for a train run where:
* 's' is an absolut point in space
* 't' is an absolut point in time
* 'vs' is a relative distance in from 's'
* 'vt' is a relative distance in from 't'
"""
function getBlockingTimesFromSnippets(transitLayer, trainleg, s_offset = 0, t_offset = 0; aggregated = true)
  preRects  = []
  coreRects = []
  postRects = []
  fullRects = []

  blocks = filter(item -> occursin(trainleg,item.name), transitLayer)
  # first_block = first(filter(item -> occursin("run-start",item.ingress_object), blocks))
  # next_block = first(filter(item -> item.ingress_object == first_block.egress_object, blocks))

  #  ──►s  (base)
  # |        O─────────────────────┐
  # |        │                     │
  # ▼ xxx    │                     │
  # t    xxx │ (joint,base_core)   │
  #          O ─────────────────── │
  #          │ xxx                 │
  #          │    xxx              │
  #          │       xxx           │
  #          │          xxx        │
  #          │             xxx     │
  #          │                xxx  │
  #          │ ─────────────────── O (stretch_core,base_post)
  #          │                     │xxx
  #          │                     │   xxx
  #          O─────────────────────
  #        (stretch_post)      
  ## init
  df = DataFrame(s=Real[], t=Real[], vs=Real[], vt=Real[], type=Symbol[],snippet_id=String[])
  s_joint = s_offset
  t_joint = t_offset
  push_pre = false
  t_pre = 0
  ## loop
  for block in blocks

    ## core blocking time
    s_base_core = s_joint
    s_stretch_core = block.core_length
    t_base_core = t_joint
    t_stretch_core = block.core_duration
    rect_core = (s = s_base_core,t = t_base_core, vs = s_stretch_core, vt = t_stretch_core, snippet_id = block.id, type = :core)
    push!(coreRects,rect_core)

    ## post blocking time
    s_base_post = s_joint
    s_stretch_post = block.core_length
    t_base_post = t_joint + block.core_duration
    t_stretch_post = block.post_duration
    rect_post = (s = s_base_post,t = t_base_post, vs = s_stretch_post, vt = t_stretch_post, snippet_id = block.id, type = :post)
    push!(postRects,rect_post)

    ## pre blocking time
    s_base_pre = s_joint
    s_stretch_pre = block.core_length
    if ! push_pre
      t_base_pre = t_joint - block.trigger_duration - block.pre_duration
    else
      t_base_pre = t_pre
    end
    t_stretch_pre = (t_joint - t_base_pre)
    rect_pre = (s = s_base_pre,t = t_base_pre, vs = s_stretch_pre, vt = t_stretch_pre, snippet_id = block.id, type = :pre)
    push!(preRects,rect_pre)

    ## full blocking time
    s_base_full = s_joint
    s_stretch_full = block.core_length
    t_base_full = t_base_pre
    t_stretch_full = t_stretch_pre + t_stretch_core + t_stretch_post
    rect_full = (s = s_base_full,t = t_base_full, vs = s_stretch_full, vt = t_stretch_full, snippet_id = block.id, type = :full)
    push!(fullRects,rect_full)

    ## next loop
    s_joint = s_joint + block.core_length
    t_joint = t_joint + block.core_duration
    push_pre = block.push_pre
    t_pre = t_base_pre
  end
  if aggregated
    for rect in fullRects
      push!(df, rect)
    end
  else
    for rect in [preRects; coreRects; postRects]
      push!(df, rect)
    end
  end
  sort!(df, [:s])
  return df
end

function minimumHeadway(blockingtimes1::DataFrame,blockingtimes2::DataFrame)
  ## check if identical length, position and have full blockingtimes
  if ! (size(blockingtimes1) == size(blockingtimes2))
    error("provided block times have different sizes!")
  end
  if !( round.(blockingtimes1.s) == round.(blockingtimes2.s))
    error("provided block times have different mileages!")
  end
  if isempty(filter(row -> row.type == :full, blockingtimes1)) || isempty(filter(row -> row.type == :full, blockingtimes2))
    error("provided block times are not of the type 'full'!")
  end
  ## 
  # @Book{Pachl:2018a,
  #   author        = {Pachl, Jörn},
  #   date          = {2018},
  #   title         = {{Systemtechnik des Schienenverkehrs}},
  #   doi           = {10.1007/978-3-658-21408-1},
  #   isbn          = {978-3-658-21408-1},
  #   language      = {german},
  #   publisher     = {Springer-Verlag},
  #   volume        = {9},
  # }
  # Page 160/161
  intersections = []
  for i in 1:length(blockingtimes1.t)
    end_block_train1 = blockingtimes1.t[i] + blockingtimes1.vt[i]
    start_block_train2 = blockingtimes2.t[i]
    intersection = end_block_train1 - start_block_train2
    push!(intersections,intersection)
  end
  return maximum(intersections)
end

function svtPlot()
  ## new but empty figure
  svt_plot = Figure()
  ## adding distance speed axis to the figure
  sv_axis = Axis(svt_plot[1,1],
      # title = "s-v-diagram",
      xlabel = "distance in km",
      xaxisposition =  :top,
      # xticks = 0:2:4,
      xticksmirrored = true,
      ylabel = "speed in km/h",
      ytickformat = "{:.1f}",
      # yticks = 0:20:40,
      yticksmirrored = true
  )
  ## adding distance time axis to the figure
  st_axis = Axis(svt_plot[2:4,1],
      # title = "s-t-diagram",
      xlabel = "distance in km",
      xaxisposition =  :bottom,
      # xticks = 0:2:4,
      xticksmirrored = true,
      ylabel = "time in min",
      ytickformat = "{:.1f}",
      yticksmirrored = true,
      yreversed = true
  )
  linkxaxes!(sv_axis, st_axis)
  return svt_plot
end

function addTrain!(
    svt_plot::Makie.Figure,
    run::DataFrame,
    blockingtimes::DataFrame=DataFrame();
    color = :blue,
    t_offset=0,
    s_offset=0
  )
  ## adding running graph
  lines!(svt_plot[1,1], run.s./1000, run.v.*3.6, color = color)
  lines!(svt_plot[2:4,1], run.s./1000, (run.t .+ t_offset)./60, color = color)
  ## adding blocking times
  for blockingtime in eachrow(blockingtimes)
    rect = Makie.Rect(blockingtime.s/1000,(blockingtime.t + t_offset)/60,blockingtime.vs/1000,blockingtime.vt/60)
    poly!(svt_plot[2:4,1], rect, color=:transparent, strokecolor = color, strokewidth = 1)
  end
  svt_plot
end

function dwellTime(dwell_time::Real; t_offset=0.0, s_offset=0.0, label::String="")
  df = DataFrame(
    label = label,
    driving_mode = "standstill",
    s = s_offset,
    v = 0.0,
    t = t_offset,
    a = 0.0,
    F_T = 0.0,
    F_R = 0.0,
    R_path = 0.0,
    R_traction = 0.0,
    R_wagons = 0.0
  )
  push!(df,(
    label = label,
    driving_mode = "standstill",
    s = s_offset,
    v = 0.0,
    t = t_offset + dwell_time,
    a = 0.0,
    F_T = 0.0,
    F_R = 0.0,
    R_path = 0.0,
    R_traction = 0.0,
    R_wagons = 0.0
  ))
  return df
end

end #module
