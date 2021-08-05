# base layer

  * what does a edge or a node represent?
    * a node could be a german "Bahnhof"; or 
    * a collective name of a berth grouping

  * usefullness of layer?
    * path traversel
    * A->B->C: does a train need to reverse direction in B?

# network layer

  * tracks - can have multiple track sections or train berths
  * junctions definied as either the american Interlocking limit by NORAC:
    "Interlocking limit: The tracks between the opposing home signals of an interlocking. - Home Signal: A fixed signal governing entrance to an interlocking or controlled point."
    or by Vakhtel:2002 "Gesamtfahrstraßenknoten"
    -> signals mark borders
    -> for block signals see speed profile layer
  * tracks and junction contradictory to Gille:2008
  * name nodes which connects to other tracks/junctions

  usefullness of layer?
    * path traversel with modified dijkstra for double vertecies
    * junction->track: is a track reachable? substitutability/vertretbarkeit?
    * calculating routing from physical layer via shortest path

# physical layer

  * double vertex graph:
    * complex implementation
    * adaption of graph mit with properties :in and :out in direction of mileage
    * path from nade X to node Y with railway typical constrains:
      * BFS
      * DFS
      * Dijkstra
      * Floyd–Warshall algorithm
      * A* search algorithm
    * Dijkstra to costly for a complete microscopic network
      -> idea if intermediate layer with lines and junctions (see Paper "Train Slots" Figure 9)
      -> new network layer
    * shortest path algorithms are to costly on full physical layer
      -> division into juctions by network layer
  
  * a directed graph can also model a common turnout, but not the signal or a crossing

  * direction in directed graph used for progression along objects
    * progression forward as in with the milage of the tracks
  
  * for this prototype no milage based on a line, but:
    * selecting one milage  out of the coverage of my scope
    * conversion to an overall single milage
  
  * base_ref connects to the BaseLayer

  * precision of pos is length 6 due to the "hoehenplan"

# speed profile layer

  * automatic creation from physical layer desired
    * physical layer needs:
    -> slope, max speed, turnout speed, radius, tunnel
  * divided into characteristic sections (CS)
    * within a CS, the maximum permissible speed and the track resistance is constant
  * network layer as a base
    * each signal represents a place where a train can stop
    -> therefore blocksignals (BK4142) in contrast to the networl layer will result in an edge