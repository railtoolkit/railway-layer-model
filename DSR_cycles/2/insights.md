# base layer

  * what does a edge or a node represent?
    * a node could be a german "Bahnhof"; or 
    * a collective name of a berth grouping
  * [3] mileage in line with network layer and speed layer (see [4,5])
    * attribute pos: for staions instead of start:, end: for lines
    * pos: attribute as list for linear location of different running lines
    * [6] change if implementaion for positioning code (see [7])

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
