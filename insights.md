# base layer

  * what does a edge or a node represent?
    * a node could be a german "Bahnhof"; or 
    * a collective name of a berth grouping

  * usefullness of layer?
    * path traversel
    * are lines connected?
    * A->B->C: does a train need to reverse direction in B?

  -------
  
  * what does a edge or a node represent?
    * a node could be a german "Bahnhof"; or 
    * a collective name of a berth grouping

  -------

  * [3] mileage in line with network layer and speed layer (see [4,5])
    * attribute pos: for staions instead of start:, end: for lines
    * pos: attribute as list for linear location of different running lines
    * [6] change if implementaion for positioning code (see [7])

  -------

  *  stations, connections & locations
    * stations as vertex and connections as edges of a graph
    * locations the mileage of lines
    * redefined "lines" into "locations"
  * a station with multiple parts can be grouped together

  -------

  * joints/conjunctions of lines/locations needed
  * renaming "locations" into "lines"
  * renaming "stations" into "locations"

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
  
  * a directed graph can also model a common turnout, but not the signal or a crossing
  * turnout/crossing complex element in railML as well: "complexType SwitchIS"
  * direction in directed graph used for progression along objects
    * progression forward as in with the milage of the tracks
    * name: branch and relation
  
  * for this prototype no milage based on a line, but:
    * selecting one milage  out of the coverage of my scope
    * conversion to an overall single milage -> missconception (see [6])
    * [7] change if implementaion for positioning code (see [6])
  * base_ref connects to the BaseLayer
  * precision of pos is length 6 due to the "hoehenplan"

  * usefullness of layer?
    * shortest path algorithms are to costly on full physical layer
      -> division into juctions by NEW network layer

  -------
  
  * network_ref connects to the NetworkLayer

  -------

  * conversion to an overall single milage -> missconception (see [6])

  -------

  * [1] the modeling of a crossing can be used for all branching objects, but the directed graph modeling of a turnout cannot be used for crossings (see [2])
    * name: branch and relation

  -------

  * speed hierachy for turnouts: default -> tilting, overweight

# network layer

  * tracks - can have multiple track sections or train berths
  * junctions definied as either the american Interlocking limit by NORAC:
    "Interlocking limit: The tracks between the opposing home signals of an interlocking. - Home Signal: A fixed signal governing entrance to an interlocking or controlled point."
    or by Vakhtel:2002 "Gesamtfahrstraßenknoten"
    -> signals mark borders
    * included specific limits in layer
    -> for block signals see resource layer
  * tracks and junction contradictory to \cite{Gille:2008}
  * name nodes which connects to other tracks/junctions
  * [4] mileage in line with base layer and speed layer (see [3,5])

  usefullness of layer?
    * path traversel with modified dijkstra for double vertecies
    * junction->track: is a track reachable? substitutability/vertretbarkeit?
    * calculating routing from physical layer via shortest path

  -------

  * specify the physical interlocking limit for "in" and "out" of a junction

  -------

  * simplify network layer with junction as vertex and link as edges (directed graph)
    * renamed "nodes" to "junctions and "connections" to "links"
    * network node either "in" or "out"
    * links - can have multiple tracks, track sections or train berths
    * junction->track: is a track reachable? substitutability/vertretbarkeit? -> solved in ResourceLayer (see [8])
    *  -> clustering of track berth in resource layer (see [8])
  * junction border is a class "sign" from physical layer

  -------

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

  -------

  * main running line / "durchgehendes Hauptgleis" need to be added

  -------
  
  * better: only links from network layer as a base
  * reduce path to only resource links from network layer
  * speed hierachy: default -> tilting, overweight

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
  * dual protection point: XPD_west/W4 with route1: A -> XPD_3 & route2: B -> XPD_1  * 
  * open points:
    * train protection system -> corresponding to detector(balise) in Physical Layer
    * interlocking logic is an open point - e.g. swinging overlap, exclusion of overlap

  * usefullness of layer?

  -------

  * devision of route signalling (interlocking layer) and block signalling (resource layer)
  * adding distant signalling for routes with braking_distance
    * to many options in case of many routes
    * can be decided upon path and technology with actuall point applies

  -------

# resource layer

  * differentiating between junctions and links from network layer
  * links from network layer git type:
    * "site" and "passage" as list in resource layer
  * composing larger area stations with different sites: e.g. Okerbach or divide Rebenau in passenger and freight site
  * borders by clearing points -> sections from physical layer
  * "virtual" smaller 'sections/physical layer' (e.g. 50 m) to accompany Moving Block with virtual blocks for transit layer and interlocking layer
  * [8] clustering of track berth for properties("vertretbarkeit"/substitutability) and naming for passengers
    * sets/ group of tracks
  * usable length for trains for atrribute berth
  
  * usefullness of layer?
    * automated dispatching \cite[p. 2-7 -- 2-12]{Pachl:1993}
      * Fahrstraßenanforderungspunkt, Einstellanstoßpunkt, Signalsichtpunkt, Bremseinsatzpunkt
      * request point, trigger point, view point, breaking point
    * trigger point 300m from breaking point fix \cite{Kuemmell:1958}
    * main signal, clearing point

  -------

  * segment id for reference needed

# transit layer

  * enable blocking time and headway time
    * switch from signal to signal based occupation time to clearing point to clearing point based occupation time
      * decribed in P.114  Pachl:2002 3.edition - no longer included in higher editions
    * trigger/breaking point still oriented towards signals
  * cases: pass, run-start, run-end, route-begin, route-extend
    * minimal snippets might be combined
    * edge cases: (swinging) overlap
  * take resource boundery from resource layer
    * push or pull
    * push suiteable for run-start
    * pull suiteable for route-extend

  -------

  * ingress and egress object needs to be unique to enable a seqence
  * seqeuncing of ingress/egress compare to a sequence number enables different combinations
  * snippets may have more parts shown on different tracks:
    * e.g. overlaps, or flank turnouts
  * speed restrictions for route an overlap
  * vehicle data ("Musterzug") should be added
  * train formations for the snippets should be added

# transport layer

  * timetabling as in a person constructing a feasible roster for trains needs to be addressed
    * train groups
    * deviations from train group
    * individual trains/courses
    * temporay trains/course
    * intervals, courses
    * connections for passengers, goods and vehicle circulations
    * margins
    * running path:
      * network link sequence
      * operational control point sequence
      * run times
      * parameters for driving behaviour
  * route and overlap
    * test if two trains have a route conflict -> interlocking layer
  * PESP (\cite{Liebchen:2007}) enabling vie the connections and trainruns
  * run time checkpoints for start and stop at berth; for pass at leaving the signal

  