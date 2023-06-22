# base layer

  * joints/conjunctions of lines/locations needed
  * renaming "locations" into "lines"
  * renaming "stations" into "locations"

# physical layer

  * speed hierachy for turnouts: default -> tilting, overweight

# speed profile layer

  * better: only links from network layer as a base
  * reduce path to only resource links from network layer
  * speed hierachy: default -> tilting, overweight

# transit layer

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
    * individual trains
    * temporay trains
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

  