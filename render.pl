#!/usr/bin/perl
print "Content-Type: text/html; charset=utf-8\r\n\r\n";

use Data::Dumper;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
use JSON;
use LWP::Simple;
use URI::Escape qw(uri_unescape uri_escape);
use Encode qw(from_to);

use lib '.';
use lib '/www/htdocs/w00fe1e3/lanes/';
use OSMData;
use OSMLanes;
use OSMDraw;



my $url = '<osm-script output="json" timeout="25"> <union> <query type="relation"> <has-kv k="TMC:cid_58:tabcd_1:LocationCode" v="8725"/> <has-kv k="TMC:cid_58:tabcd_1:Direction" v="negative" /> </query> </union> <print mode="body" order="id"/> <recurse type="down"/> <print order="quadtile"/> </osm-script>';

my $start = 1;
my $placementactive = "";
my $adjacentactive = "";
my $lanewidthactive = "";
my $extrasizeactive = "";

if(defined $ENV{'QUERY_STRING'}) {
  my @args = split("&",$ENV{'QUERY_STRING'});
  foreach my $a (@args) {
    my @v = split('=',$a,2);
    if($v[0] eq 'url')      {$url   = uri_unescape($v[1]); from_to ($url,"utf-8","iso-8859-1"); $url =~ s/\+/ /g;} #
    if($v[0] eq 'start')    {$start = uri_unescape($v[1]);}
    if($v[0] eq 'placement'){$placement = "checked"; $placementactive = "placement"}
    if($v[0] eq 'adjacent') {$adjacent = "checked"; $adjacentactive = "adjacent"}
    if($v[0] eq 'lanewidth') {$lanewidth = "checked"; $lanewidthactive = "adjacent"}
    if($v[0] eq 'extrasize') {$extrasize = "checked"; $extrasizeactive = "extrasize"; $LANEWIDTH *= 1.5 if $extrasize;}
    }
  }

OSMData::readData($url); 
OSMData::organizeWays();


my $totalstartpoints = 0;
my $startcnt = $start;
## Find the Nth starting point
my $currid;
foreach my $w (sort keys %{$waydata}) {
  if (!defined $waydata->{$w}->{before}) {
    $totalstartpoints++;
    if($startcnt > 0) {
      $currid = $w;
      $waydata->{$w}->{reversed} = 0;
      --$startcnt;
      }
    }
  elsif (!defined $waydata->{$w}->{after}) {
    $totalstartpoints++;
    if($startcnt > 0) {
      $currid = $w;
      $waydata->{$w}->{reversed} = 1;
      --$startcnt;
      }
    }
  }
  
my $id = $currid;
#Reverse ways where needed
while(1) {
  last if $waydata->{$id}{checked};
  $waydata->{$id}{checked} = 1;
  
  if($waydata->{$id}->{reversed}) {
    my $tmp = $waydata->{$id}{end};
    $waydata->{$id}{end} = $waydata->{$id}{begin};
    $waydata->{$id}{begin} = $tmp;
    
    $tmp = $waydata->{$id}{after};
    $waydata->{$id}{after} = $waydata->{$id}{before};
    $waydata->{$id}{before} = $tmp;
    
    my @tmp = reverse @{$waydata->{$id}{nodes}};
    $waydata->{$id}{nodes} = \@tmp;
    }
    
  last unless defined $waydata->{$id}{after};
#   my $nextid = $waydata->{$id}{after}[0];
  my $nextid = OSMDraw::getBestNext($id);
  if($waydata->{$id}{end} == $waydata->{$nextid}{end}) {
    $waydata->{$nextid}->{reversed} = 1;
    }
  else {
    $waydata->{$nextid}->{reversed} = 0;
    }
  $id = $nextid;  
  }

if($adjacent) {
  #Get adjacent ways
  my $str = '<osm-script output="json" timeout="25"><union>';
  foreach my $w (keys %{$waydata}) {
    next unless $waydata->{$w}{checked};
    $str .= '<id-query ref="'.$waydata->{$w}{end}.'" type="node"/>'
    }
  $str .= '</union>  <print />  <recurse type="node-way"/>  <print />  <recurse type="down"/>    <print /> </osm-script>';  

  OSMData::readData($str,1); 


  }

my $urlescaped = uri_escape($url);

print <<HDOC;
<!DOCTYPE html>
<html lang="en">
<head>
 <title>Lanes</title>
 <link rel="stylesheet" type="text/css" href="../lanes/style.css">
 <meta  charset="UTF-8"/>

<script type="text/javascript">
  function changeURL(x) {
    var url = "";
    var enteredtext = document.getElementsByName(x)[0].value;
    if( x == 'relref' ) {
      url += '<osm-script output="json" timeout="25"><union><query type="relation"><has-kv k="ref" v="'+enteredtext+'"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';
      }
    if( x == 'relname' ) {
      url += '<osm-script output="json" timeout="25"><union><query type="relation"><has-kv k="name" v="'+enteredtext+'"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';
      }
    if( x == 'relid' ) {
      url += '<osm-script output="json" timeout="25"><union><query type="relation"><id-query ref="'+enteredtext+'" type="relation"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';
      }
    if( x == 'wayid' ) {
      url += '<osm-script output="json" timeout="25"><union><query type="way"><id-query ref="'+enteredtext+'" type="way"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';
      }      
    url = encodeURI(url);
    window.location.href="?url="+url+"&start=$start&$placementactive&$adjacentactive&$lanewidthactive&$extrasizeactive";
    }
</script>
</head>
<body class="$extrasizeactive">
<h1>Lane Visualizer</h1>
<p>Enter a valid overpass query that delivers a list of continuous ways, e.g. as shown here: <a href="http://overpass-turbo.eu/s/6vr">Overpass Turbo</a>. Just put the Overpass query to the text box.
<br>As there are several "last ways" (at least two...) in each data set, select one by putting a number in the box below. All tags of a way are shown as mouse-over on the text "way" on the left side.
<br>Currently supported: lanes, turn:lanes, change:lanes, maxspeed, overtaking, destination*.
<br>20.12.14: Added support for destination:ref and bridges
<br>26.12.14: Added support for destination, length and distance of ways
<br>26.12.14: Added forms for simple requests
<br>30.12.14: Option to analyze adjacent ways and intersection geometries. If enabled, the geometry of ways at each connection between two road pieces is shown. Additional roads are shown in green (Note the mouse-over text with all tags and the link to the way in OSM)
<br>10.01.15: Direct jump to a given segment of the road - just add "#WAYID" to the very end of the URL. Fixed utf-8 issue in queries (Thanks to MKnight for reporting!)
<br>23.01.15: Added a bit of support for destination:symbol and destination:colour
<br>29.01.15: Support for destination:country
<br>All code is available on <a href="https://github.com/mueschel/OSMLaneVisualizer">GitHub</a>.

<form action="render.pl" method="get" style="display:block;float:left;">
<textarea name="url" cols="50" rows="5">$url</textarea><br>
<label><input type="text" name="start" value="$start">(Found a total of $totalstartpoints end nodes)<br></label>
<label><input type="checkbox" name="placement" $placement>Use placement</label>
<label><input style="margin_left:30px;" type="checkbox" name="adjacent" $adjacent>Use adjacent ways</label>
<label><input style="margin_left:30px;" type="checkbox" name="lanewidth" $lanewidth>Use lane width</label>
<label><input style="margin_left:30px;" type="checkbox" name="extrasize" $extrasize>Larger lanes<br></label>
<label><input type="submit" value=" Get ">
</form>

<div style="display:block;float:left;">
Search for: (Important: only short roads (<100km highway). Total execution time exceeds a limit quite easily)
<ul><li>A relation with ref = <input type="text" name="relref" value="A 661"><input type="submit" value=" Go " onClick="changeURL('relref');">
<li>A relation with name = <input type="text" name="relname" value="Bundesstraße 521"><input type="submit" value=" Go " onClick="changeURL('relname');">
<li>A relation with id = <input type="text" name="relid" value="11037"><input type="submit" value=" Go " onClick="changeURL('relid');">
<li>A way with id = <input type="text" name="wayid" value="324294469"><input type="submit" value=" Go " onClick="changeURL('wayid');">
</ul>
<a target="_blank" href="http://overpass-turbo.eu/?Q=$urlescaped">Show in Overpass Turbo</a>
</div>

<hr style="margin-bottom:20px;margin-top:10px;clear:both;">
HDOC


my @outarr;


while(1) {
  last if defined $waydata->{$currid}{used};
  $waydata->{$currid}{used} = 1;
  
  push(@outarr,OSMDraw::drawWay($currid));

  last unless defined $waydata->{$currid}{after};
#   $currid = $waydata->{$currid}{after}[0];
  $currid = OSMDraw::getBestNext($currid);
  }

  
print reverse @outarr;  

print "</body></html>";
1;
