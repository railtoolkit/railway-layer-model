# Open Points and To Dos

## General

* only attributes from the Y->S perspective: many more needed for a productive environment

* data acquisitions and maintenance

* large/complex/real-life network test needed

* general refinement and implementation
  * implementation with MultiLayerGraphs.jl
  * modularity and the possibility to add new layers
  * coordinates for visualisation
  * calculate plot coordination for different layers
  * junction direction with two lines with opposing mileage directions


## Layer modifications

* misalignment between timing checkpoints for timetabling and real-time data from track occupation data

* time frame periods for infrastructure validity like in the Transport Layer, but for every Layer

* Network Layer:
  * move distinguishing of passage/site to Resource Layer

* Speed Profile Layer:
  * modify Speed Profile Layer to extend coverage further than the running lines
  * [1] graph instead of a list/array; see also [2]

* Interlocking Layer:
  * interlocking logic
  * collections of entrances instead of a continuous list
  * shunting routes
  * level crossings
  * permissible train protection system
  * make breaking_distance optional

* Resource Layer:
  * dispatching rules
  * trigger points for dispatching and dispatching rules in Interlocking Layer and Resource Layer
  * monitoring points and berth offsets for timetable analysis
  * improving alignment between ingress/egress objects from Transit Layer and (site/passage) track sections from Resource Layer, including junctions from Interlocking Layer
    * could be done by the decision on the use of information from the physical layer if to use the element or the segment OR including junction into the Resource layer to provide the ingress and egress objects.
  * [2] improving alignment between sections in Resource Layer and sections in Speed Profile Layer; see also [1]

* Transit Layer:
  * reference in snippets for valid formations

* Transport Layer:
  * GTFS and NeTEx compatibility
  * reference run/service to Resource Layer via passage/site
  * reference service to Resource Layer via berth


## New Layers?

* Power Layer
  * electrification
  * power signals
  * power modelling

* Operation Layer
  * crew rooster
  * vehicle circulation

* Physical Layer
  * track geometry

* Clearance Layer(?!? different name OR part of existing layers) 
  * clearance gauge
  * gauge
  * permissible axle load
  * permissible attribute from Interlocking Layer or Power Layer
