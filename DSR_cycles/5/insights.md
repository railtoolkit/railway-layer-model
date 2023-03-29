# network layer

  * specify the physical interlocking limit for "in" and "out" of a junction

# physical layer

  * [1] the modeling of a crossing can be used for all branching objects, but the directed graph modeling of a turnout cannot be used for crossings (see [2])
    * name: branch and relation

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
