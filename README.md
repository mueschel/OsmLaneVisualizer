OsmLaneVisualizer
=================
A simple tool to show lane attributes of way data in OSM. Data can be fetched from Overpass API, output is created as Html code.

The code is free to use under conditions of cc-by-nc-sa (http://creativecommons.org/licenses/by-nc-sa/4.0/)

Interpreted Tags
--------------
*  lanes, lanes:forward, lanes:backward  
   Used to determine the number of lanes. Might be overruled by other tags
   
*  maxspeed  
   * maxspeed[:lanes][:forward|:backward]   
    Supported, shown on left-hand side. Displayed inside lane for lane dependent tags
    
  * maxspeed:hgv    
    Supported, shown on left-hand side, no lane or direction dependence
    
  * maxspeed:conditional    
    Supported, shown on left-hand side, no lane or direction dependence
    
*  oneway  
   Mostly supported, oneway=-1 might fail in some cases
   
    


Number of Lanes
---------------
The number of lanes is determined by reading all tags of way containing a :lanes part and the lanes tag itself.
For both forward and backward direction, the maximal number is used - this might not be the intended number of lanes
but helps to find tagging errors (e.g. stray pipes)
