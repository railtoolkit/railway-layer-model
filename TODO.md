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

* misalignment between timing checkpoints for timetabling and real-time data from track occupation data

* improving alignment between ingress/egress objects from Transit Layer and (site/passage) track sections from Resource Layer, including junctions from Interlocking Layer
  * could be done by the decision on the use of information from the physical layer if to use the element or the segment OR including junction into the Resource layer to provide the ingress and egress objects.

* time frame periods for infrastructure like in the Transport Layer, but for every Layer

## Layer modifications

* modify Speed Profile Layer to extend coverage further than the running lines
  * graph instead of a list/array

* Interlocking Layer
  * interlocking logic
  * collections of entrances instead of a continuous list
  * shunting routes
  * level crossings
  * permissible train protection system

* Resource Layer
  * dispatching rules
  * trigger points for dispatching and dispatching rules in Interlocking Layer and Resource Layer
  * monitoring points and berth offsets for timetable analysis


* Transport Layer
  * GTFS and NeTEx compatibility

## New Layers

* Power Layer
  * electrification
  * power signals
  * power modelling

* Operation Layer
  * crew rooster
  * vehicle circulation

* Physical Layer
  * track geometry

* Clearance Layer
  * clearance gauge
  * gauge
  * permissible axle load
  * permissible attribute from Interlocking Layer or Power Layer
