# base layer

  * [3] mileage in line with network layer and speed layer (see [4,5])
    * attribute pos: for staions instead of start:, end: for lines
    * pos: attribute as list for linear location of different running lines
    * [6] change if implementaion for positioning code (see [7])

# physical layer

  * conversion to an overall single milage -> missconception (see [6])

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
