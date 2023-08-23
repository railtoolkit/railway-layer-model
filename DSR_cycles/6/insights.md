# base layer

  *  locations, connections & locations
    * locations as vertex and connections as edges of a graph
    * locations the mileage of lines
    * redefined "lines" into "locations"
  * a station with multiple parts can be grouped together

# network layer

  * simplify network layer with junction as vertex and link as edges (directed graph)
    * renamed "nodes" to "junctions and "connections" to "links"
    * network node either "in" or "out"
    * links - can have multiple tracks, track segments or train berths
    * junction->track: is a track reachable? substitutability/vertretbarkeit? -> solved in ResourceLayer (see [8])
    *  -> clustering of track berth in resource layer (see [8])
  * junction border is a class "sign" from physical layer

# speed profile layer

  * main running line / "durchgehendes Hauptgleis" need to be added

# interlocking layer

  * devision of route signalling (interlocking layer) and block signalling (resource layer)
  * adding distant signalling for routes with braking_distance
    * to many options in case of many routes
    * can be decided upon path and technology with actuall point applies

# resource layer

  * differentiating between junctions and links from network layer
  * links from network layer git type:
    * "site" and "passage" as list in resource layer
  * composing larger area locations with different sites: e.g. Okerbach or divide Rebenau in passenger and freight site
  * borders by clearing points -> segments from physical layer
  * "virtual" smaller 'segments/physical layer' (e.g. 50 m) to accompany Moving Block with virtual blocks for transit layer and interlocking layer
  * [8] clustering of track berth for properties("vertretbarkeit") and naming for passengers
    * sets/ group of tracks
  
  * usefullness of layer?
    * automated dispatching \ref[p. 2-7 -- 2-12]{Pachl:1993}
      * Fahrstraßenanforderungspunkt, Einstellanstoßpunkt, Signalsichtpunkt, Bremseinsatzpunkt
      * request point, trigger point, view point, breaking point
    * trigger point 300m from breaking point fix \ref{Kuemmell:1958}
    * main signal, clearing point