#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.6.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

module Console

include("LMcore.jl")
include("PhysicalLayer.jl")
using .LMcore, .PhysicalLayer

using UUIDs
using LightGraphs, MetaGraphs
# using GraphPlot

function main()
  println("Manual Input for a PhysicalLayer")
  println("Load previous graph? (y/N) ")
  answer = readline()
  if answer in ("Y","y","J","j","Z","z","YES","yes","Yes")
    print("file name? ")
    file_path = readline()
    if !endswith(file_path, ".yaml")
      file_path = file_path * ".yaml"
    end
    graph = PhysicalLayer.load(file_path)
  else
    # construct MetaDiGraph with node and edges
    graph = MetaGraphs.MetaDiGraph(0)
    MetaGraphs.defaultweight!(graph, NaN)
  end
  #
  while true
    printHelpMessage()
    #
    # try
      print("command? ")
      userinput = readline()
      if     userinput in ("T","t")
        userAddTrack!(graph)
      elseif userinput in ("E","e")
        userAddElement!(graph)
      elseif userinput in ("C","c")
        userConnect!(graph)
      elseif userinput in ("I","i")
        userInsertElement!(graph)
      elseif userinput in ("L","l")
        userList(graph)
      # elseif userinput in ("P","p")
      #   LMcore.show(graph)
      elseif userinput in ("S","s")
        userSave(graph)
      elseif userinput in ("X","x")
        println("Exiting.")
        break
      else
        println("Did not recognize command.\n")
      end
    # catch err
    #   println("\nAn error occured in the last use function.")
    #   println("Error type: $err")
    # end
  end
end # function main

function printHelpMessage()
  println("")
  println("==========================================")
  println("t - add a new track section to the graph")
  println("e - add an element to the graph")
  println("c - connect elements with track sections")
  println("i - insert element in a track section")
  # println("m - modify an element")
  println("l - List all current track sections or elements")
  # println("p - plot current graph")
  println("s - save current graph")
  println("x - exit")
  println("==========================================")
end # function helpMessage

function userAddTrack!(graph)
  println("adding track\n")
  # enter track name
  print("enter a track section id: ")
  track_id = readline()
  # enter startKM and endKM - sorting!
  print("start KM: ")
  startKM = readline()
  try
    startKM = parse(Float64, startKM)
  catch err
    if isa(err, ArgumentError)
      println(err)
      return
    end
  end
  print("end KM: ")
  endKM = readline()
  try
    endKM = parse(Float64, endKM)
  catch err
    if isa(err, ArgumentError)
      println(err)
      return
    end
  end
  if startKM > endKM
    println("Error: endKM comes before startKM - wrong milage!")
    return
  end
  # enter startElement and endElement: create if not existent
  println("connect with existing elemets?")
  print("y/N? ")
  answer = readline()
  if answer in ("Y","y","J","j","Z","z","YES","yes","Yes")
    connect = true
  else
    connect = false
  end
  #
  if connect
    print("element id of source node: ")
    source_id = readline()
    print("element id of target node: ")
    target_id = readline()
    source = first(MetaGraphs.filter_vertices(graph, :id, source_id))
    target = first(MetaGraphs.filter_vertices(graph, :id, target_id))
  else
    source_id = track_id * "_ingress"
    target_id = track_id * "_egress"
    source = addElement!(graph, source_id)
    target = addElement!(graph, target_id)
    MetaGraphs.set_prop!(graph, source, :pos, startKM)
    MetaGraphs.set_prop!(graph, source, :type, "end")
    MetaGraphs.set_prop!(graph, target, :pos, endKM)
    MetaGraphs.set_prop!(graph, target, :type, "end")
  end
  LightGraphs.add_edge!(graph, source, target)
  MetaGraphs.set_prop!(graph, LightGraphs.Edge(source, target), :id, track_id)
  MetaGraphs.set_prop!(graph, LightGraphs.Edge(source, target), :length, endKM - startKM)
end # function userAddTrack!

function userAddElement!(graph, node_id = -1)
  println("==========================================")
  println("Adding new element\n")
  println("Specify element type!")
  println("1 - branch | 2 - crossing | 3 - sign | 4 - detector | 5 - anchor | 6 - end")
  print("type? (1 - 6) ")
  userinput = readline()
  if     userinput == "1"
    type = "branch"
  elseif userinput == "2"
    type = "crossing"
  elseif userinput == "3"
    type = "sign"
  elseif userinput == "4"
    type = "detector"
  elseif userinput == "5"
    type = "anchor"
  elseif userinput == "6"
    type = "end"
  else
    println("Did not recognize type.\n")
    return false
  end

  println("creating new $type element")
  if node_id == -1
    print("specify element id (leave empty to omit): ")
    node_id = readline()
    if isempty(node_id)
      node_id = string(UUIDs.uuid4())
    end
  end
  if !LMcore.has_node(graph, node_id)
    node = addElement!(graph, node_id)
  else
    println("Element with ID $node_id already exists in the graph!")
    return false
  end
  MetaGraphs.set_prop!(graph, node, :type, type)

  print("Position KM: ")
  pos = readline()
  try
    if occursin(",", pos)
      pos = replace(pos, "," => ".")
    end
    pos = parse(Float64, pos)
  catch err
    println(err)
    return false
  end
  MetaGraphs.set_prop!(graph, node, :pos, pos)

  if type == "sign"
    println("Specify element class!")
    println("1 - signal | 2 - board | 3 - berth")
    print("class? (1 - 3) ")
    userinput = readline()
    if     userinput == "1"
      class = "signal"
    elseif userinput == "2"
      class = "board"
    elseif userinput == "3"
      class = "berth"
    else
      println("Did not recognize class.\n")
      return false
    end
    MetaGraphs.set_prop!(graph, node, :class, class)
  elseif type == "detector"
    println("Specify element class!")
    println("1 - clearing point | 2 - transmitter")
    print("class? (1 or 2) ")
    userinput = readline()
    if     userinput == "1"
      class = "clearing point"
    elseif userinput == "2"
      class = "transmitter"
    else
      println("Did not recognize class.\n")
      return false
    end
    MetaGraphs.set_prop!(graph, node, :class, class)
  elseif type == "branch"
    MetaGraphs.set_prop!(graph, node, :in, LightGraphs.Edge[])
    MetaGraphs.set_prop!(graph, node, :out, LightGraphs.Edge[])
  elseif type == "crossing"
    MetaGraphs.set_prop!(graph, node, :link, Tuple{LightGraphs.Edge, LightGraphs.Edge}[])
  elseif type == "end"
    println("Specify element class!")
    println("1 - buffer stop | 2 - continuious track")
    print("class? (1 or 2) ")
    userinput = readline()
    if     userinput == "1"
      class = "buffer stop"
    elseif userinput == "2"
      class = "continuing"
    else
      println("Did not recognize class.\n")
      return false
    end
    MetaGraphs.set_prop!(graph, node, :class, class)
  end

  if type == "sign"
    println("Specify element working direction!")
    println("1 - forward | 2 - backward | 3 - bidirectional")
    print("direction!? (1 - 3) ")
    userinput = readline()
    if     userinput == "1"
      direction = "forward"
    elseif userinput == "2"
      direction = "backward"
    elseif userinput == "3"
      direction = "bidirectional"
    else
      println("Did not recognize direction!.\n")
      return false
    end
    MetaGraphs.set_prop!(graph, node, :direction, direction)
  end
  if type == "detector"
    MetaGraphs.set_prop!(graph, node, :direction, "bidirectional")
  end

  return node_id
end # function userAddElement!

function userConnect!(graph)
  println("==========================================")
  println("Connecting elements with track sections\n")

  # asked for source of the connection
  print("element id of source node: ")
  source_id = readline()
  if LMcore.has_node(graph, source_id)
    source = first(MetaGraphs.filter_vertices(graph, :id, source_id))
  else
    println("Element with ID $source_id does not exist in the graph!")
    return false
  end
  # asked for ID of the connection
  print("enter a track section id: ")
  track_id = readline()
  if LMcore.has_edge(graph, track_id)
    println("Element with ID $track_id already exists in the graph!")
    return false
  end
  # asked for destination of the connection
  print("element id of target node: ")
  target_id = readline()
  if LMcore.has_node(graph, target_id)
    target = first(MetaGraphs.filter_vertices(graph, :id, target_id))
  else
    println("Element with ID $target_id does not exist in the graph!")
    return false
  end
  ###
  LightGraphs.add_edge!(graph, source, target)
  MetaGraphs.set_prop!(graph, LightGraphs.Edge(source, target), :id, track_id)

  # determine length
  startKM = MetaGraphs.get_prop(graph, source, :pos)
  endKM = MetaGraphs.get_prop(graph, target, :pos)
  length = endKM - startKM
  MetaGraphs.set_prop!(graph, LightGraphs.Edge(source, target), :length, length)

  # special handling for branches
  if MetaGraphs.get_prop(graph, source, :type) == "branch"
    tmp = MetaGraphs.get_prop(graph, source, :out)
    push!(tmp, LightGraphs.Edge(source,target))
  end
  if MetaGraphs.get_prop(graph, target, :type) == "branch"
    tmp = MetaGraphs.get_prop(graph, target, :in)
    push!(tmp, LightGraphs.Edge(source,target))
  end

  # special handling for crossings
  for node in (source,target)
    if MetaGraphs.get_prop(graph, node, :type) == "crossing"
      if MetaGraphs.has_prop(graph, node, :to_link)
        to_link = MetaGraphs.get_prop(graph, node, :to_link)
        print("Link $track_id with: ")
        n = 1
        for opposing_edge in to_link
          opposing_edge_id = MetaGraphs.get_prop(graph, opposing_edge, :id)
          print("$n - $opposing_edge_id ")
          n += 1
        end
        println("\nselect number of id or omit for none")
        i = readline()
        try
          i = parse(Int64,i)
        catch
        end
        if isa(i, Int64)
          opposing_edge_id = MetaGraphs.get_prop(graph, to_link[i], :id)
          connect = true
        else
          connect = false
        end
        
        if connect
          link = MetaGraphs.get_prop(graph, node, :link)
          if LightGraphs.dst(to_link[i]) == node
            push!(link, (to_link[i], LightGraphs.Edge(source,target)))
          else
            push!(link, (LightGraphs.Edge(source,target), to_link[i]))
          end
          # remove from prop :to_link
          println("All connections with track setion $opposing_edge_id attached?")
          print("y/N? ")
          answer = readline()
          if answer in ("Y","y","J","j","Z","z","YES","yes","Yes")
            deleteat!(to_link, i)
          end
          
          if isempty(to_link)# if prop :to_link empty remove prop
            MetaGraphs.rem_prop!(graph, node, :to_link)
          end
        else
          push!(to_link, LightGraphs.Edge(source,target))
        end

      else
        to_link  = LightGraphs.Edge[]
        push!(to_link, LightGraphs.Edge(source,target))
        MetaGraphs.set_prop!(graph, node, :to_link, to_link)
      end
    end
  end

end # function userConnect!

function userInsertElement!(graph)
  println("inserting element")
  print("specify element id: ")
  node_id = readline()
  # test if node_id exists
  node_in_graph = LMcore.has_node(graph, node_id)
  if !node_in_graph
    println("Element $node_id does not exist.")
    print("Create it? (Y/n) ")
    answer = readline()
    if answer in ("N","n","No","NO","no")
    else
      userAddElement!(graph, node_id)
      node_in_graph = true
    end
  end
  #
  if node_in_graph
    print("specify track section id to insert element in: ")
    track_id = readline()
    edge = first(MetaGraphs.filter_edges(graph, :id, track_id))
    # test if edge exists
    if !LightGraphs.has_edge(graph, edge)
      println("Error: track section not known!")
    else
      insertElement!(graph, edge, node_id)
    end
    #
  end
end # function userInsertElement!

function userList(graph)
  println("==========================================")
  println("a - listing all")
  println("t - listing track sections")
  println("e - listing elements")
  while true
    print("command? ")
    userinput = readline()
    if     userinput in ("E","e")
      listElements(graph)
      break
    elseif userinput in ("T","t")
      listTrackSections(graph)
      break
    elseif userinput in ("A","a")
      listElements(graph)
      listTrackSections(graph)
      break
    else
      println("Did not recognize command.\n")
    end
  end
end # function userList

function userSave(graph)
  print("file name? ")
  file_path = readline()
  if !endswith(file_path, ".yaml")
    file_path = file_path * ".yaml"
  end
  PhysicalLayer.save(graph, file_path)
  println("Graph saved in $file_path")
end # function userSave

##===================================##
## function without user interaction ##
##===================================##

function addElement!(graph, node_id)
  LightGraphs.add_vertex!(graph)
  MetaGraphs.set_prop!(graph, LightGraphs.nv(graph), :id, node_id)
  return LightGraphs.nv(graph)
end # function addElement!

function insertElement!(graph, edge, node_id)
  x = first(MetaGraphs.filter_vertices(graph, :id, node_id))
  u,v = LightGraphs.src(edge), LightGraphs.dst(edge)
  pos_x = MetaGraphs.get_prop(graph, x, :pos)
  pos_u = MetaGraphs.get_prop(graph, u, :pos)
  pos_v = MetaGraphs.get_prop(graph, v, :pos)
  track_id = MetaGraphs.get_prop(graph, edge, :id)
  track_length = MetaGraphs.get_prop(graph, edge, :length)
  # test if pos_x is within the edge
  if pos_u > pos_x > pos_v
    println("Error: Position of inserted node not wthin the track section!")
    return
  end
  # determine new length
  if (pos_u - pos_v) == track_length
    length_1 = pos_x - pos_u
    length_2 = pos_v - pos_x
  end
  #
  LightGraphs.rem_edge!(graph, edge)
  LightGraphs.add_edge!(graph, u, x)
  LightGraphs.add_edge!(graph, x, v)

  print("Choose name for track section id BEFORE $node_id: ")
  before = readline()
  print("Choose name for track section id AFTER $node_id: ")
  after = readline()
  if isempty(before) | !LMcore.has_edge(graph, before)
    MetaGraphs.set_prop!(graph, LightGraphs.Edge(u,x), :id, track_id * "_1")
  else
    MetaGraphs.set_prop!(graph, LightGraphs.Edge(u,x), :id, before)
  end
  if isempty(after) | !LMcore.has_edge(graph, after)
    MetaGraphs.set_prop!(graph, LightGraphs.Edge(x,v), :id, track_id * "_2")
  else
    MetaGraphs.set_prop!(graph, LightGraphs.Edge(x,v), :id, after)
  end

  MetaGraphs.set_prop!(graph, LightGraphs.Edge(u,x), :length, length_1)
  MetaGraphs.set_prop!(graph, LightGraphs.Edge(x,v), :length, length_2)
end # function insertElement!

function listElements(graph)
  println("\nElements:")
  for vertex in LightGraphs.vertices(graph)
    print("  No.: ")
    print(vertex)
    print("  ID: ")
    print(MetaGraphs.get_prop(graph, vertex, :id))
    print("  type: ")
    print(MetaGraphs.get_prop(graph, vertex, :type))
    print("  pos: ")
    print(MetaGraphs.get_prop(graph, vertex, :pos))
    println("")
  end
end # function listElements

function listTrackSections(graph)
  println("\nTrack sections:")
  for edge in LightGraphs.edges(graph)
    # print("  ")
    # print(edge)
    print("  ID: ")
    print(MetaGraphs.get_prop(graph, edge, :id))
    print("  length: ")
    print(MetaGraphs.get_prop(graph, edge, :length))
    print("  src: ")
    print(LightGraphs.src(edge))
    print("  dst: ")
    print(LightGraphs.dst(edge))
    println("")
  end
end # function listTrackSections

end # module Console