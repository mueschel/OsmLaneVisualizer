OsmLaneVisualizer
=================
A simple tool to show lane attributes of way data in OSM. Data can be fetched from Overpass API, output is created as Html code.

**&lt;Advertisment&gt;Support for at least 105 different keys (that's more than a standard US keyboard!).&lt;/Advertisment&gt;**

The code is free to use under conditions of cc-by-nc-sa (http://creativecommons.org/licenses/by-nc-sa/4.0/)


Interpreted Tags
--------------
*  **bicycle[:lanes][:forward|:backward]** The values no, designated and official are displayed
*  **bridge[:name]** Bridges are displayed using a shadow behind the lanes, the name is shown
*  **bus[:lanes][:forward|:backward]** The values designated and official are displayed
*  **change[:lanes][:forward|:backward]** Shown as solid or dashed lines between lanes
*  **destination[:lanes][:forward|:backward]** Shown using german-style destination signs.
*  **destination:colour[:lanes][:forward|:backward]** Used as background color for individual destinations on a sign.
*  **destination:country[:lanes][:forward|:backward]** If the number of entries matches the number of destination's, the country codes are listed next to the destination, otherwise they are grouped at the bottom of the sign.
*  **destination:ref[:lanes][:forward|:backward]** Shown using german-style destination signs. The ref's are listed at the bottom of each sign
*  **destination:symbol[:lanes][:forward|:backward]** Some common symbols are displayed. They are listed next to destination names
*  **foot[:lanes][:forward|:backward]** The values no, designated and official are displayed
*  **highway=motorway_junction** Junction name and ref are displayed, if they are located at the end of a way
*  **hgv[:lanes][:forward|:backward]** The values no, designated and official are displayed
*  **lanes[:forward|:backward|:both_ways]**  Used to determine the number of lanes. Might be overruled by other tags
*  **maxspeed**  
 * **maxspeed[:lanes][:forward|:backward]**  Supported, shown on left-hand side. Displayed inside lane for lane dependent tags
 * **maxspeed:conditional**   Supported, shown on left-hand side, no lane or direction dependence.
 * **maxspeed:hgv**   Supported, shown on left-hand side, no lane or direction dependence
*  **motorroad** If yes, the corresponding sign is shown
*  **name** Shown in left column
*  **oneway**  Mostly supported, oneway=-1 might fail in some cases
*  **psv[:lanes][:forward|:backward]** The values designated and official are displayed
*  **ref** Shown in left column
*  **shoulder[:left|:right]** Shoulders are drawn as gray area left and right of the road
*  **tunnel:name** Name is shown if available
*  **turn[:lanes][:forward|:backward]** Rendered by using Unicode characters. 
*  **overtaking** Shown as solid line between forward and backward lanes
*  **placement[:forward|:backward]** Used for positioning lanes if enabled
*  **width[:lanes][:forward|:backward]** Used if enabled


Number of Lanes
---------------
The number of lanes is determined by reading all tags of way containing a :lanes part and the lanes tag itself.
For both forward and backward direction, the maximal number is used - this might not be the intended number of lanes
but helps to find tagging errors (e.g. stray pipes)
