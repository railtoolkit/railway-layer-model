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
    * calculating routing from physical layer via shortest path

# physical layer

  * network_ref connects to the NetworkLayer