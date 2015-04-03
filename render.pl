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
my $totalstartpoints = 0;
my $extendway = 0;
my $extrasizeactive = "";
my $currid;
my $opts;

if(defined $ENV{'QUERY_STRING'}) {
  my @args = split("&",$ENV{'QUERY_STRING'});
  foreach my $a (@args) {
    my @v = split('=',$a,2);
    $v[1] = uri_unescape($v[1]); from_to ($v[1],"utf-8","iso-8859-1"); $v[1] =~ s/\+/ /g;
    $opts->{$v[0]} = $v[1] || 1;
    if($v[0] eq 'url')      {$url   = $v[1];}
    if($v[0] eq 'start')    {$start = $v[1];}
    if($v[0] eq 'placement'){$USEplacement = "checked";}
    if($v[0] eq 'adjacent') {$adjacent = "checked";}
    if($v[0] eq 'lanewidth') {$lanewidth = "checked";}
    if($v[0] eq 'extendway') {$extendway = "checked";}
    if($v[0] eq 'extrasize') {$extrasize = "checked"; $extrasizeactive = "&extrasize"; $LANEWIDTH *= 1.53 if $extrasize;}
    if($v[0] eq 'wayid') {$url = '<osm-script output="json" timeout="25"><union><query type="way"><id-query ref="'.($v[1]).'" type="way"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';}
    if($v[0] eq 'relid') {$url = '<osm-script output="json" timeout="25"><union><query type="relation"><id-query ref="'.($v[1]).'" type="relation"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';}
    if($v[0] eq 'relname') {$url = '<osm-script output="json" timeout="25"><union><query type="relation"><has-kv k="name" v="'.($v[1]).'"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';}
    if($v[0] eq 'relref') {$url = '<osm-script output="json" timeout="25"><union><query type="relation"><has-kv k="ref" v="'.($v[1]).'"/></query></union><print mode="body" order="quadtile"/><recurse type="down"/><print  order="quadtile"/></osm-script>';}
    }
  }

  
  
my $r = OSMData::readData($url,0); 
unless($r) {
  #if only one way found, try to extent it a bit
  if($extendway && scalar keys %{$waydata} <= 4) {
    my $ref; my $id;
    foreach my $x (keys %{$waydata}) {
      $id  = $x;
      $ref = $waydata->{$x}{tags}{'ref'};
      }
    OSMData::readData('[out:json][timeout:25];(  way('.$id.');  >;  way(bn);  >;  way(bn);)->.a;(  way.a[highway][ref="'.$ref.'"];  >;);out body qt;',0);
    }
  
  
  OSMData::organizeWays();



  my $startcnt = $start;
  ## Find the Nth starting point
  
  foreach my $w (sort keys %{$waydata}) {
    if (!defined $waydata->{$w}->{before}) {
      $totalstartpoints++;
      if($startcnt > 0) {
        $currid = $w;
        $waydata->{$w}->{reversed} = 0;
        --$startcnt;
        }
      }
    }
  foreach my $w (sort keys %{$waydata}) {   
    if (!defined $waydata->{$w}->{after}) {
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
  }
my $urlescaped = uri_escape($url);
my $querystring = $ENV{'QUERY_STRING'};
my $wayid = $opts->{'wayid'} || 324294469;
my $relid = $opts->{'relid'} || 11037;
my $relname = $opts->{'relname'} || 'Bundesstraße 521';
my $relref  = $opts->{'relref'} || 'A 661';

print <<HDOC;
<!DOCTYPE html>
<html lang="en">
<head>
 <title>OSM Lane Visualizer</title>
 <link rel="stylesheet" type="text/css" href="../lanes/style.css">
 <meta  charset="UTF-8"/>

<script type="text/javascript">
  function changeURL(x) {
    var url = "?";
    url += x+'='+encodeURI(document.getElementsByName(x)[0].value);
    url += "&start="+document.getElementsByName('start')[0].value;
    url += document.getElementsByName('placement')[0].checked?"&placement":"";
    url += document.getElementsByName('adjacent')[0].checked?"&adjacent":"";
    url += document.getElementsByName('lanewidth')[0].checked?"&lanewidth":"";
    url += document.getElementsByName('extrasize')[0].checked?"&extrasize":"";
    url += document.getElementsByName('extendway')[0].checked?"&extendway":"";
    window.location.href=url;
    }
</script>
</head>
<body class="$extrasizeactive">
<h1>OSM Lane Visualizer</h1>
<p>Enter a valid overpass query that delivers a list of continuous ways, e.g. as shown here: <a href="http://overpass-turbo.eu/s/6vr">Overpass Turbo</a>. Just put the Overpass query to the text box.
<br>As there are several "last ways" (at least two...) in each data set, select one by putting a number in the box below. All tags of a way are shown as mouse-over on the text "way" on the left side.
<br><a href="https://github.com/mueschel/OsmLaneVisualizer#interpreted-tags">Currently supported keys.</a> All code is available on <a href="https://github.com/mueschel/OSMLaneVisualizer">GitHub</a>. Pictures are linked from wikimedia-commons.

<div class="config">
<h3>Configuration</h3>
<label title="Evaluate the placement tag to get a more natural arrangement of lanes">
  <input type="checkbox" name="placement" $USEplacement>Use placement</label>
<br><label title="Show the geometry of all ways joining at the end nodes of each segment">
  <input style="margin_left:30px;" type="checkbox" name="adjacent" $adjacent >Use adjacent ways</label>
<br><label title="Determine width of lanes from width tag. Note that this does not work well in combination with destination signs">
  <input style="margin_left:30px;" type="checkbox" name="lanewidth" $lanewidth >Use lane width</label>
<br><label title="Increase the size of all lanes by 50% in each direction">
  <input style="margin_left:30px;" type="checkbox" name="extrasize" $extrasize >Larger lanes</label>
<br><label title="If the API call returns a single way, look for up to two ways in front and after the found one with the same ref-tag">
  <input style="margin_left:30px;" type="checkbox" name="extendway" $extendway >Include ways before &amp; after</label>
<br><label>Start at end number <input type="text" name="start" value="$start" style="width:30px;">(Found a total of $totalstartpoints end nodes)</label>
</div>

<div class="selectquery">
<h3>Search for:</h3>
<p><label>A relation with ref = <input type="text" name="relref" value="$relref"></label><input type="button" value=" Go " onClick="changeURL('relref');">
<br><label>A relation with name = <input type="text" name="relname" value="$relname"></label><input type="button" value=" Go " onClick="changeURL('relname');">
<br><label>A relation with id = <input type="text" name="relid" value="$relid"></label><input type="button" value=" Go " onClick="changeURL('relid');">
<br><label>A way with id = <input type="text" name="wayid" value="$wayid"></label><input type="button" value=" Go " onClick="changeURL('wayid');">
<br>Important: Please don't select relations with too many members (less than 200 seems ok)
</div>

<div class="selectquery" style="width:350px;">
<h3 title="Enter any valid Overpass query that returns a more or less contiguous list of not too many highways">The query</h3>
<textarea name="url" cols="45" rows="5">$url</textarea>
<br><input type="button" value=" Go " onClick="changeURL('url');">
<hr>
<a target="_blank" href="http://overpass-turbo.eu/?Q=$urlescaped">Show in Overpass Turbo</a>
<br><a href="http://osm.mueschelsoft.de/lanes/render.pl?$querystring">Link to this page</a>
</div>

<hr style="margin-bottom:50px;margin-top:10px;clear:both;">
HDOC

unless($r) {
  my @outarr;


  while(1) {
    last if defined $waydata->{$currid}{used};
    $waydata->{$currid}{used} = 1;
    
    push(@outarr,OSMDraw::drawWay($currid));

    last unless defined $waydata->{$currid}{after};
    $currid = OSMDraw::getBestNext($currid);
    }

    
  print reverse @outarr;  
  }
 
print "</body></html>";
1;
