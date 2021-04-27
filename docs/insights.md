# base layer

what does a edge or a node represent?
  * a node could be a german "Bahnhof"; or 
  * a collective name of a berth grouping

usefullness of layer?
  * path traversel
  * A->B->C: does a train need to reverse direction in B?

# physical layer

double vertex graph
  * complex implementation
  * adaption of graph mit with properties :in and :out in direction of mileage
  * path from nade X to node Y with railway typical constrains:
    * BFS
    * DFS
    * Dijkstra
  * modified version of Dijkstra-algo
  * Dijkstra to costly for a complete microscopic network
    -> idea if intermediate layer with lines and junctions (see Paper "Train Slots" Figure 9)
  