#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2023"
# __license__       = "ISC"

module TransitLayer

include("LMcore.jl")
import .LMcore
include("PhysicalLayer.jl")
import .PhysicalLayer
# include("NetworkLayer.jl")
# import .NetworkLayer
# include("InterlockingLayer.jl")
# import .InterlockingLayer

using YAML, DataFrames, TrainRuns, UUIDs, MetaGraphs

export load, save, Path, getMovingSection

# ===========================
"""
Takes a YAML-file and extracts the Speed Profile Layer Attributes.
Returns a MetaGraph object.
"""
function loadSnippets(file_path)

  snippets = YAML.load(open(file_path))["transit"]["snippets"]

  blockingtimes = BlockingTimeSnippet[]
  for snippet in snippets
    push!(blockingtimes,BlockingTimeSnippet(
      snippet["id"],
      snippet["name"],
      snippet["description"],
      snippet["ingress_object"]["associated"],
      snippet["egress_object"]["associated"],
      Symbol(snippet["direction"]),
      snippet["core_length"],
      snippet["core_duration"],
      snippet["trigger_duration"],
      snippet["pre_duration"],
      snippet["post_duration"],
      Symbol(snippet["ingress_type"]),
      Symbol(snippet["egress_type"]),
      snippet["push_pre"]))
  end

  return blockingtimes

end # function load

"""
"""
function saveSnippets(file_path, snippets::Vector{Any})

  # TODO error handling
  tmp_array = []
  for snippet in snippets
    tmp = Dict()
    tmp["id"]               = snippet.id
    tmp["name"]             = snippet.name
    tmp["description"]      = snippet.description
    tmp["ingress_object"]   = snippet.ingress_object
    tmp["egress_object"]    = snippet.egress_object
    tmp["direction"]        = snippet.direction
    tmp["core_length"]      = snippet.core_length
    tmp["core_duration"]    = snippet.core_duration
    tmp["trigger_duration"] = snippet.trigger_duration
    tmp["pre_duration"]     = snippet.pre_duration
    tmp["post_duration"]    = snippet.post_duration
    tmp["ingress_type"]     = snippet.ingress_type
    tmp["egress_type"]      = snippet.egress_type
    tmp["push_pre"]         = snippet.push_pre
    push!(tmp_array,tmp)
  end
  YAML.write_file(file_path, Dict("transit" => Dict("snippets" => tmp_array)))
end # function saveSnippets

"""
###
position relateted: ingress route egress block
time related: start route end
"""
struct BlockingTimeSnippet
  id::String             #
  name::String           #
  description::String    #
  ingress_object::String #
  egress_object::String  #
  direction::Symbol      # :forward, :backward, :bidirectional
  core_length::Real      #
  core_duration::Real    #
  trigger_duration::Real #
  pre_duration::Real     #
  post_duration::Real    #
  ingress_type::Symbol   # :pass, :halt
  egress_type::Symbol    # :pass, :halt
  push_pre::Bool         #
end # struct BlockingTimeSnippet

"""
outer constructor for struct BlockingTimeSnippet with
calculation of snippet attributes:
core_length,core_duration,trigger_duration,pre_duration,post_duration,ingress_type,egress_type,push_pre
"""
function getSnippet(run::DataFrame, entry_point::String, exit_point::String;
                    type::Symbol = :pass,
                    direction::Symbol = :forward,
                    id = UUIDs.uuid4(),
                    name::String = "",
                    description::String = "",
                    reaction_time::Real = 10,
                    grant_authoriy_time::Real = 2,
                    release_time::Real = 2)
  
  push_pre = false
  ingress_type = :pass
  egress_type = :pass

  trigger  = filter(row -> occursin(entry_point,row.label) && occursin("trigger" ,row.label)        && occursin("front" ,row.label), run)
  breaking = filter(row -> occursin(entry_point,row.label) && occursin("breaking" ,row.label)       && occursin("front" ,row.label), run)
  ingress  = filter(row -> occursin(entry_point,row.label) && occursin("block clearing" ,row.label) && occursin("front" ,row.label), run)
  egress   = filter(row -> occursin(exit_point,row.label)  && occursin("block clearing" ,row.label) && occursin("front" ,row.label), run)
  clear    = filter(row -> occursin(exit_point,row.label)  && occursin("block clearing" ,row.label) && occursin("rear" ,row.label),  run)

  if type == :run_start
    core    = filter(row -> string(row.driving_mode) == "breakFree", run)
    core_length      = round(abs(egress[1,:s] - ingress[1,:s]))
    core_duration    = round(abs(egress[1,:t] - core[1,:t]))
    trigger_duration = reaction_time + grant_authoriy_time
    pre_duration     = 0.0
    post_duration    = release_time + clear[1,:t]
    ingress_type     = :halt
    push_pre         = true
  elseif type == :run_end
    ingress = filter(row -> occursin(entry_point,row.label) && occursin("clearing" ,row.label) && occursin("front" ,row.label), run)
    core    = filter(row -> string(row.driving_mode) == "halt", run)
    core_length      = round(abs(egress[1,:s] - ingress[1,:s]))
    core_duration    = round(abs(core[1,:t] - ingress[1,:t]))
    if isempty(trigger)
      trigger_duration = 0.0
    else
      trigger_duration = round(abs(breaking[1,:t] - trigger[1,:t]))
    end
    if isempty(breaking)
      pre_duration = 0.0
    else
      pre_duration = abs(ingress[1,:t] - breaking[1,:t])
    end
    post_duration    = release_time
    egress_type      = :halt
  elseif type == :route_begin
    egress  = filter(row -> occursin(exit_point,row.label)  && occursin("route clearing" ,row.label) && occursin("front" ,row.label), run)
    core_length      = round(abs(egress[1,:s] - ingress[1,:s]))
    core_duration    = round(abs(egress[1,:t] - ingress[1,:t]))
    if isempty(trigger)
      trigger_duration = reaction_time + grant_authoriy_time
    else
      trigger_duration = round(abs(breaking[1,:t] - trigger[1,:t]))
    end
    if isempty(breaking)
      pre_duration = 0.0
    else
      pre_duration = round(abs(ingress[1,:t] - breaking[1,:t]))
    end
    post_duration    =  round(release_time + clear[1,:t])
    push_pre = true
  elseif type == :route_extend
    ingress = filter(row -> occursin(entry_point,row.label) && occursin("route clearing" ,row.label) && occursin("front" ,row.label), run)
    core_length      = round(abs(egress[1,:s] - ingress[1,:s]))
    core_duration    = round(abs(egress[1,:t] - ingress[1,:t]))
    trigger_duration = 0.0
    pre_duration     = 0.0
    post_duration    = round(release_time + clear[1,:t])
  else # type == :pass
    core_length      = round(abs(egress[1,:s] - ingress[1,:s]))
    core_duration    = round(abs(egress[1,:t] - ingress[1,:t]))
    if isempty(trigger)
      trigger_duration = reaction_time + grant_authoriy_time
    else
      trigger_duration = round(abs(breaking[1,:t] - trigger[1,:t]))
    end
    if isempty(breaking)
      pre_duration = 0.0
    else
      pre_duration = round(abs(ingress[1,:t] - breaking[1,:t]))
    end
    post_duration    = round(release_time + clear[1,:t])
  end

  # println("description: ", description)
  # println("ingress_object: ", ingress_object)
  # println("egress_object: ", egress_object)
  # println("core_length: ", core_length)
  # println("core_duration: ", core_duration)
  # println("trigger_duration: ", trigger_duration)
  # println("pre_duration: ", pre_duration)
  # println("post_duration: ", post_duration)

  return TransitLayer.BlockingTimeSnippet(string(id),name,description,entry_point,exit_point,direction,core_length,core_duration,trigger_duration,pre_duration,post_duration,ingress_type,egress_type,push_pre)
end

function getMovingSection(characteristic_sections, start_mileage, end_mileage)
  df = copy(characteristic_sections)
  sort!(df, [:position])
  upper = filter(:position => n -> n < start_mileage, df)
  filter!(:position => n -> n >= start_mileage && n <= end_mileage, df)
  if ! isempty(upper)
    upper_speed = last(upper)[:speed]
    upper_resistance = last(upper)[:resistance]
    pushfirst!(df, Dict(:position => start_mileage, :speed => upper_speed, :resistance => upper_resistance))
  end
  if ! (last(df)[:position] == end_mileage)
    # last_row = pop!(df)
    lower_speed = last(df)[:speed]
    lower_resistance = last(df)[:resistance]
    push!(df, Dict(:position => end_mileage, :speed => lower_speed, :resistance => lower_resistance))
  end
  return df
end

function extendCharacteristicSections!(df, distance)
  first_row = first(df)
  last_row = last(df)
  upper_start = first_row[:position] - distance
  upper_speed = first_row[:speed]
  upper_resistance = 0.0
  lower_speed = last_row[:speed]
  lower_resistance = 0.0
  lower_start = last_row[:position] + distance
  pushfirst!(df, Dict(:position => upper_start, :speed => upper_speed, :resistance => upper_resistance))
  push!(df,      Dict(:position => lower_start, :speed => lower_speed, :resistance => lower_resistance))
end


"""
takes a train run and returns snippets borders and info with:
  * snippet type
  * ingress object
  * egress object
as DataFrame
"""
function getSnippetInfo(running_times::DataFrame)
  snippettype = Array{Union{Symbol,Missing},1}(missing, size(running_times,1))
  ingressobject = Array{Union{String,Missing},1}(missing, size(running_times,1))
  egressobject = Array{Union{String,Missing},1}(missing, size(running_times,1))
  previous_type_pos = 1
  previous_clearing = ""
  for row in eachrow(running_times)
    # println(type_pos)
    base_ref,name,object,measure = split(row.label, ":")
    if occursin("clearing",object) && measure == "front"
      # push!(snippetborder, true)
      if previous_clearing == "route clearing" && object == "block clearing"
        snippettype[previous_type_pos] = :route_extend
      elseif previous_clearing == "route clearing" && object == "route clearing"
        snippettype[previous_type_pos] = :route_extend
      elseif previous_clearing == "block clearing" && object == "route clearing"
        snippettype[previous_type_pos] = :route_begin
      else
        if previous_type_pos == 1
          snippettype[rownumber(row)] = :run_start
        else
          snippettype[previous_type_pos] = :pass
        end
      end
      # snippettype[type_pos] = name
      if name == "run-end"
        snippettype[previous_type_pos] = :run_end
      end
      egressobject[previous_type_pos] = base_ref * ":" * name
      ingressobject[rownumber(row)] = base_ref * ":" * name
      previous_type_pos = rownumber(row)
      previous_clearing = object
    else
      # push!(snippetborder, false)
    end
  end
  df = DataFrame()
  df.type = snippettype
  df.ingress = ingressobject
  df.egress = egressobject
  dropmissing!(df)
  return df
end


function addClearingAtEdge!(clearingtimes::DataFrame,physicalLayer::AbstractMetaGraph)
  allowmissing!(clearingtimes)

  base_ref1,name1 = split(first(clearingtimes)[:label], ":")
  # println(name1)
  if name1 != "fictitious"
    node1 = PhysicalLayer.get_node_num(physicalLayer, name1, base_ref1)
    node2 = LMcore.get_nextnode(physicalLayer, node1, :kind, "clearing point", "backward")
    dist12 = PhysicalLayer.get_node_distance(physicalLayer, node1, node2) * 1000
    pushfirst!(clearingtimes, Dict(:label => base_ref1 * ":run-start:block clearing:front", :s => (first(clearingtimes)[:s]-dist12)), cols = :subset)
  end
  base_ref3,name3 = split(last(clearingtimes)[:label], ":")
  if name3 != "fictitious"
    node3 = PhysicalLayer.get_node_num(physicalLayer, name3, base_ref3)
    node4 = LMcore.get_nextnode(physicalLayer, node3, :kind, "clearing point", "forward")
    dist34 = PhysicalLayer.get_node_distance(physicalLayer, node3, node4) * 1000
    push!(     clearingtimes, Dict(:label => base_ref3 * ":run-end:block clearing:front",   :s => (last(clearingtimes)[:s]+dist34)), cols = :subset)
  end
end

end #module
