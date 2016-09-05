OsmLaneVisualizer
=================
A simple tool to show lane attributes of way data in OSM. Data can be fetched from Overpass API, output is created as Html code.

**&lt;Advertisment&gt;Support for at least 105 different keys (that's more than a standard US keyboard!).&lt;/Advertisment&gt;**

The code is free to use under conditions of cc-by-nc-sa (http://creativecommons.org/licenses/by-nc-sa/4.0/)

How to get data
--------------
Option 1: Enter a way or relation id, or the ref or name of a relation into the appropriate box and click the "GO" button next to it.

Option 2: Enter your own query or a valid json object (as output by Overpass) into the box "The Query" and click the "GO" button.

If you change configuration (read the mouse-over text for explanations), click the same "GO" button again.


Interpreted Tags
--------------
*  **bicycle[:lanes][:forward|:backward|:both_ways]** The values no, designated and official are displayed
*  **bridge[:name]** Bridges are displayed using a shadow behind the lanes, the name is shown
*  **bus[:lanes][:forward|:backward|:both_ways]** The values designated and official are displayed
*  **change[:lanes][:forward|:backward|:both_ways]** Shown as solid or dashed lines between lanes
*  **destination[:lanes][:forward|:backward|:both_ways]** Shown using german-style destination signs.
*  **destination:colour[:lanes][:forward|:backward|:both_ways]** Used as background color for individual destinations on a sign.
*  **destination:country[:lanes][:forward|:backward|:both_ways]** If the number of entries matches the number of destination's, the country codes are listed next to the destination, otherwise they are grouped at the bottom of the sign.
*  **destination:ref[:lanes][:forward|:backward|:both_ways]** Shown using german-style destination signs. The ref's are listed at the bottom of each sign
*  **destination:ref:to[:lanes][:forward|:backward|:both_ways]** Shown using german-style destination signs. The ref's are listed at the bottom of each sign
*  **destination:symbol[:lanes][:forward|:backward|:both_ways]** Some common symbols are displayed. They are listed next to destination names
*  **destination:symbol:to[:lanes][:forward|:backward|:both_ways]** Some common symbols are displayed. They are listed next to destination names
*  **destination:to:ref[:lanes][:forward|:backward|:both_ways]** Shown using german-style destination signs. The ref's are listed at the bottom of each sign
*  **foot[:lanes][:forward|:backward|:both_ways]** The values no, designated and official are displayed
*  **highway=motorway_junction** Junction name and ref are displayed, if they are located at the end of a way
*  **highway=(traffic_signals|give_way|stop|crossing|mini_roundabout)** Some highway tags on nodes are shown using the corresponding traffic sign
*  **hgv[:lanes][:forward|:backward|:both_ways]** The values no, designated and official are displayed
*  **int_ref** Shown in left column and on signs
*  **junction=roundabout** Roundabouts are marked
*  **lanes[:forward|:backward|:both_ways]**  Used to determine the number of lanes. Might be overruled by other tags
*  **maxspeed**  
 * **maxspeed[:lanes][:forward|:backward|:both_ways]**  Supported, shown on left-hand side. Displayed inside lane for lane dependent tags
 * **maxspeed:conditional**   Supported, shown on left-hand side, no lane or direction dependence.
 * **maxspeed:hgv**   Supported, shown on left-hand side, no lane or direction dependence
*  **motorroad** If yes, the corresponding sign is shown
*  **name** Shown in left column
*  **oneway**  Mostly supported, oneway=-1 might fail in some cases
*  **overtaking[:hgv][:forward|:backward]** Shown as solid line between forward and backward lanes
*  **placement[:forward|:backward][:start|:end]** Used for positioning lanes if enabled. Additional: Experimental support for a tag proposed by Imagic to give further detail in case of placement=transistion
*  **psv[:lanes][:forward|:backward|:both_ways]** The values designated and official are displayed
*  **ref** Shown in left column, used to determine color of signs
*  **shoulder[:left|:right]** Shoulders are drawn as gray area left and right of the road
*  **sidewalk[:left|:right|:both]** Shown in light blue on left and right side of the road
*  **sidewalk[:left|:right|:both]:width** Used if enabled
*  **traffic_calming=island** Shown on ways between lanes as dark area
*  **traffic_calming:width** Used if enabled
*  **tunnel:name** Name is shown if available
*  **turn[:lanes][:forward|:backward|:both_ways]** Rendered by using Unicode characters. 
*  **width[:lanes][:forward|:backward]** Used if enabled


Number of Lanes
---------------
The number of lanes is determined by reading all tags of way containing a :lanes part and the lanes tag itself.
For both forward and backward direction, the maximal number is used - this might not be the intended number of lanes
but helps to find tagging errors (e.g. stray pipes).