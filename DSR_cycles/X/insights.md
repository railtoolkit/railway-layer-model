# base layer

  * what does a edge or a node represent?
    * a node could be a german "Bahnhof"; or 
    * a collective name of a berth grouping
  * [3] mileage in line with network layer and speed layer (see [4,5])
    * attribute pos: for staions instead of start:, end: for lines
    * pos: attribute as list for linear location of different running lines
    * [6] change if implementaion for positioning code (see [7])

  * usefullness of layer?
    * path traversel
    * are lines connected (see [3])
    * A->B->C: does a train need to reverse direction in B?

# network layer

  * tracks - can have multiple track sections or train berths
  * junctions definied as either the american Interlocking limit by NORAC:
    "Interlocking limit: The tracks between the opposing home signals of an interlocking. - Home Signal: A fixed signal governing entrance to an interlocking or controlled point."
    or by Vakhtel:2002 "Gesamtfahrstraßenknoten"
    -> signals mark borders
    * included specific limits in layer
    -> for block signals see speed profile layer
  * tracks and junction contradictory to Gille:2008
  * name nodes which connects to other tracks/junctions
  * [4] mileage in line with base layer and speed layer (see [3,5])

  usefullness of layer?
    * path traversel with modified dijkstra for double vertecies
    * junction->track: is a track reachable? substitutability/vertretbarkeit?
      -> clustering of track berth (see [8])
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
  * turnout/crossing complex element in railML as well: "complexType SwitchIS"
  * direction in directed graph used for progression along objects
    * progression forward as in with the milage of the tracks
  * [1] the modeling of a crossing can be used for all branching objects, but the directed graph modeling of a turnout cannot be used for crossings (see [2])
    * name: branch and relation
  
  * for this prototype no milage based on a line, but:
    * selecting one milage  out of the coverage of my scope
    * conversion to an overall single milage -> missconception (see [6])
    * [7] change if implementaion for positioning code (see [6])
  * base_ref connects to the BaseLayer
  * precision of pos is length 6 due to the "hoehenplan"

  * usefullness of layer?

# speed profile layer

  * automatic creation from physical layer desired
    * physical layer needs:
    -> slope, max speed, radius (turnout speed), tunnel
    * turnout speed information depends on turnout specimen
  * divided into characteristic sections (CS)
    * within a CS, the maximum permissible speed and the track resistance is constant
  * network layer as a base
    * each signal represents a place where a train can stop
    -> therefore blocksignals (BK4142) in contrast to the networl layer will result in an edge
    * a network junction might have different dimensions depend on the used track. i.e. XR_west to track 1 ends earlier then to track 2
    -> network references do make limited sense
    -> a lookup table (how to implement?) for A:pos to B:pos with the resistance
  * slope is valid for all routes in a network junction
  * radius and thus vmax speed for a junction depends on the physical path from the physical layer
    -> also relevant for the interlocking layer
    -> routine to include radius and v_max
    -> speed attribute also part of the physicalLayer in turnouts/crossings (see [2])
  * actual speed of train depends on combinations of track, train, dispatching (see Process Map of Railway Operation) and current behavior section (BS)
  * [5] mileage in line with base layer and network layer (see [3,4])

  * usefullness of layer?
    * running time calculation
    * resistance
    * main running line / "durchgehendes Hauptgleis"
    * correct speed limit determination at junction of two lines (e.g from XSZ to XPX via XBU)

# interlocking layer

  * differentiation between route start and route end at a signal:
    - route start (entrance): destination, locked turnouts, flank zone, route clearing points
    - route end (exit): overlap
  * howto include speed restrictions from shortened overlap? -> seperate attribute "speed" with default value ".inf"
  * needs to know speed restrictions from divirgent track at turnout/crossing (see speed layer) -> can be taken from turouts en route
  * turnout/crossing position information must be stored for route as well for flank protection for the use of a route
    * different modelling of branch and branches for turnout en route and turouts in flankprotection: see W3 in XPD in route "track3" from A
  * [2] turnout/crossing speed must be derived from lower layer -> changed modelling of turnout/crossing for physicalLayer (see [1])
    * derailer need to provide status and position
  * speed restrictions cannot be derived from radius, since the jerk is relevant
  * currently only train routes, no shunting routes
  * redefined "junction" of network layer
  * dual protection point: XPD_west/W4 with route1: A -> XPD_3 & route2: B -> XPD_1

  * usefullness of layer?

# resource layer

  * differentiating bewteen junctions and tracks from network layer
  * borders by clearing points
  * "virtual" smaller 'tracksections/physical layer' (e.g. 50 m) to accompany Moving Block with virtual blocks for transit layer and interlocking layer
  * [8] clustering of track berth for properties("vertretbarkeit") and naming for passengers
  
  * usefullness of layer?

# transit layer

  * sequence of 'tracksections/resource layer' from physical layer together with occupation time for different types of trains ("Musterzug")
  * berth nodes for dwell time (see [8])

  * usefullness of layer?