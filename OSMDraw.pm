package OSMDraw;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';
use OSMData;
use OSMLanes;
use List::Util qw(min max);

my $totallength = 0;


#################################################
## Returns one or two symbols for maxspeed, 
## separated forward and backward direction if needed
#################################################
sub makeMaxspeed {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
  my $out = '';
  
  my $maxforward  = $t->{'maxspeed:forward'}  || $t->{'maxspeed'} || 'unkwn';
  my $maxbackward = $t->{'maxspeed:backward'} || $t->{'maxspeed'} || 'unkwn';
  my $fwdclass = $maxforward; my $bckclass = $maxbackward;
  $maxforward =~ s/none//;
  $maxbackward =~ s/none//;
  
  if($maxforward eq $maxbackward) {
    $out = '<div class="max '.$fwdclass.'">'.$maxforward.'</div>';
    }
  elsif ($waydata->{$id}{reversed}) {  
    $out  = '<div class="max fwd '.$fwdclass.'">'.$maxforward.'</div>';
    $out .= '<div class="max bck '.$bckclass.'">'.$maxbackward.'</div>';
    }
  else {
    $out  = '<div class="max bck '.$bckclass.'">'.$maxbackward.'</div>';
    $out .= '<div class="max fwd '.$fwdclass.'">'.$maxforward.'</div>';
    }
  if ($t->{'maxspeed:hgv'})  {
    $out .= '<div class="maxcont">';
    $out .= '<div class="max ">'.($t->{'maxspeed:hgv'}).'</div>';
    $out .= '<div class="condition hgv">&nbsp;</div>';
    $out .= '</div>';
    }
  if ($t->{'maxspeed:conditional'})  {
    my $str = $t->{'maxspeed:conditional'};
    while ($str =~ /([^\(;]+)\s*@\s*(\(([^\)]+)\)|([^;]+))/g) {
      my $what = $1;
      my $when = $3.$4;
      my $title = $1.' @ '.$3.$4;
      my $class;
      $when =~ s/:00//g;
      if($when eq 'wet') {$when = ''; $class="wet";}
      $out .= '<div class="maxcont" title="'.$title.'">';
      $out .= '<div class="max ">'.$what.'</div>';
      $out .= '<div class="condition '.$class.'">'.$when.'</div>';
      $out .= '</div>';
      }
    }
    
  return $out;
  }
  
#################################################
## Make a full destination sign for one lane
#################################################   
sub makeDestination {
  my ($lane,$way,$lanes,$option) = @_;
  my $o = "";
  my $cr = "K";
  my $dest    = $lanes->{destination}[$lane];
  my $roadref = $way->{'ref'};
  my $ref     = $lanes->{destinationref}[$lane];
  my $destcol = $lanes->{destinationcolour}[$lane];
  my $destsym = $lanes->{destinationsymbol}[$lane];
  my $destcountry = $lanes->{destinationcountry}[$lane];
  my $titledest = $dest;
  my $signdest  = $dest;

  $ref =~ s/;/ \/ /g;
  $signdest =~ s/;/<br>/g;
  $titledest =~ s/;/\n/g;  
  $destsym =~ s/none//g;
  
  if($ref || $dest || $destsym || $destcountry) {
    $o .= '<div class="refcont">';
    unless($option =~ /notooltip/) {
      $o .= '<div class="tooltip">'.$ref.'<br>'.$signdest.'</div>';
      }
    
    $cr = 'K';
    $cr = "B" if $roadref =~ /^\s*B/;
    $cr = "A" if $roadref =~ /^\s*A/ || $ref =~ /^\s*A/;

    
    $o .='<div class="'.$cr.'" >';
    my @dests = split(";",$dest,-1);
    my @cols  = split(";",$destcol,-1);
    my @syms  = split(";",$destsym,-1);
    my @ctr   = split(';',$destcountry,-1);

    for (my $i = 0; $i < max(scalar @dests,scalar @syms); $i++ ) {
      if($cols[$i]) {
        my $tc = '';
        if($cols[$i] eq 'white' || $cols[$i] =~ /ffffff/) { $tc = 'color:black;';}
        if($cols[$i] eq 'blue') {$tc = 'color:white';}
        $cols[$i] = 'style="background-color:'.$cols[$i].';';
        $cols[$i] .= $tc.'"';
        }
      if($syms[$i]) {
        if(!$dests[$i]) {$syms[$i] .= " symbolonly";}
        else {$syms[$i] .= " symbol";}
        }
      $syms[$i] = "dest ".$syms[$i];
      $o .= '<div class="'.$syms[$i].'"><span '.$cols[$i].'>'.($dests[$i]||"&nbsp;").'</span>';
      $o .= '<span class="destCountry">'.$ctr[$i].'</span>' if(scalar @ctr == scalar @dests && $ctr[$i] ne 'none' && $ctr[$i]);
      $o .= '</div>';
      }

    $o .= '<div class="clear">&nbsp;</div>'; 
 
    if(scalar @ctr != scalar @dests) {
      foreach my $c (@ctr) {
        next if $c eq 'none';
        $o .= '<div class="destCountry">'.$c.'</div>';
        }
      }

    if($ref) {
      my @refs = split('/',$ref);
      foreach my $r (reverse @refs) {
        $cr = "A" if $r =~ /^\s*A/;
        $cr = "B" if $r =~ /^\s*B/;
        unless($r =~ '^\s*$') {
          $o .='<div class="ref'.$cr.'">'.$r.'</div>';
          }
        }
      }  
    $o .= "</div></div>";  
    }
  return $o;  
  }
  
sub makeAllDestinations {
  my $id = shift @_;
  my $st = shift @_;
  my $option = shift @_;
  my $t;
  my $lanes;
  
  $t = $store->{way}[$st]{$id}{tags};
  $lanes = $store->{way}[$st]{$id}{lanes};

  
  my @destinations;
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    my $dest  = OSMDraw::makeDestination($i,$t,$lanes,$option);
    push(@destinations,$dest);
    }
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    if(@destinations[$i]) {  
      my $w = '';
      if (@destinations[$i] eq @destinations[$i+1]) {
        $w = 'double';
        @destinations[$i+1] = '';
        if (@destinations[$i] eq @destinations[$i+2]) {
          $w = 'triple';
          @destinations[$i+2] = '';
          if (@destinations[$i] eq @destinations[$i+3]) {
            $w = 'quadruple';
            @destinations[$i+3] = '';
            }
          }
        }
      @destinations[$i] = '<div class="destination '.$w.'">'.@destinations[$i].'</div>';  
      }
    } 
  return \@destinations;
  }
  
  
#################################################
## Format the "ref" of a way
################################################# 
sub makeRef {
  my ($ref) = @_;
  my $o ='';
  if($ref) {
    my $cr = 'K';
    my @refs = split(';',$ref);
    foreach my $r (reverse @refs) {
      $cr = "A" if $r =~ /^\s*A/;
      $cr = "B" if $r =~ /^\s*B/;
      if($r ne '') {
        $o .='<div class="ref'.$cr.'">'.$r.'</div>';
        }
      }
    }
  return $o;
  }
  
#################################################
## In case the way splits, the best choice is the one with the smallest turning angle
#################################################
sub getBestNext {  
  my $id = shift @_;
  my $angle = 0;
  my $minangle = 180;
  my $realnext;
  my $fromdirection = OSMData::calcDirection($nodedata->{$waydata->{$id}{nodes}[-1]},$nodedata->{$waydata->{$id}{nodes}[-2]});
  
  return unless defined $waydata->{$id}{after};
  foreach my $nx (@{$waydata->{$id}{after}}) {
    $angle = OSMData::calcDirection($nodedata->{$waydata->{$nx}{nodes}[1]},$nodedata->{$waydata->{$nx}{nodes}[0]});
    $angle = $fromdirection-$angle;
    $angle = OSMData::NormalizeAngle($angle);
    $angle = abs($angle);
    if($angle < $minangle) {
      $minangle = $angle;
      $realnext = $nx;
      }
    }
  return $realnext;  
  }

#################################################
## Generate arrows for turn-lanes
#################################################  
sub makeTurns {
  my $t = ';'.shift @_;
  my $dir = shift @_;
  my $o = "";
  $o .= '<div class="turns '.$dir.'">';
  if ($t =~ /reverse/)        {$o .="&#x21b6;";}
  if ($t =~ /merge_to_left/)  {$o .="<div style=\"display:inline-block;transform: rotate(45deg)\">&#x293A;</div>";}
  if ($t =~ /sharp_left/)     {$o .="&#x2198;";}
  if ($t =~ /;left/)          {$o .="&#x21B0;";}
  if ($t =~ /slight_left/)    {$o .="&#x2196;";}
  if ($t =~ /through/)        {$o .="&#x2191;";}
  if ($t =~ /slight_right/)   {$o .="&#x2197;";}
  if ($t =~ /;right/)         {$o .="&#x21B1;";}
  if ($t =~ /sharp_right/)    {$o .="&#x2199;";}
  if ($t =~ /merge_to_right/) {$o .="<div style=\"display:inline-block;transform: rotate(225deg)\">&#x2938;</div>";}
  $o .= "</div>";
  return $o;
  }

#################################################
## Draw a sketch of all ways joining in a given node
#################################################    
sub makeWaylayout {
  my $id = shift @_;
  my $out = "";
  my $cntways = 0;
  my $connectsangle = -400;
  my $connectsid = 0;
  $out .= '<div class="waylayout">';
  my $stangle = OSMData::calcDirection($store->{node}[0]{$waydata->{$id}{nodes}[-1]},
                                        $store->{node}[0]{$waydata->{$id}{nodes}[-2]})
                                        -90;
  foreach my $i (@{$endnodes->[1]{$waydata->{$id}{end}}}) {
    my $nd = 0;
    $nd = $store->{way}[1]{$i}{nodes}[1]     if ($store->{way}[1]{$i}{nodes}[0] == $waydata->{$id}{end});
    $nd = $store->{way}[1]{$i}{nodes}[-2]    if ($store->{way}[1]{$i}{nodes}[-1] == $waydata->{$id}{end});
    my $angle = sprintf("%.1f",OSMData::NormalizeAngle(OSMData::calcDirection($store->{node}[1]{$waydata->{$id}{end}},$store->{node}[1]{$nd})-$stangle));
    my $main =  (defined $waydata->{$i})?'main':'';
    if($main) {
      my $from = ($i == $id)?'from':'';
      $out .= '<div class="connects '.$main.' '.$from.'" style="transform:rotate('.$angle.'deg)">&nbsp;</div>';
      }
    else {
      my $title = OSMData::listtags($store->{way}[1]{$i});
      $cntways++;
      $connectsangle = $angle;
      $connectsid = $i;
      $out .= '<a href="https://www.openstreetmap.org/way/'.$i.'" target="_blank"><div class="connects" style="transform:rotate('.$angle.'deg)" title="Way '.$i."\n".$title.'" >&nbsp;</div></a>';
      }
    }
  $out .= '</div>';
  
  if(scalar @{$endnodes->[1]{$waydata->{$id}{end}}} >= 3 && $cntways == 1 && (($connectsangle > -160 && $connectsangle < -20) || $connectsangle > 200)) { #if only one way and in forward direction
    OSMLanes::InspectLanes($store->{way}[1]{$connectsid});
    
    $out .= '<div class="connectdestination">';
    my $d = OSMDraw::makeAllDestinations($connectsid,1,'notooltip');
    foreach my $l (@{$d}) {
      $out .= $l;
      }
    $out .= '</div>';
    }
  return $out;  
  }

#################################################
## draws shoulders of ways
#################################################  
sub makeShoulder {
  my $obj = shift @_;
  my $o = '';
  my $shoulder = $obj->{tags}{'shoulder'};
  my $bridge= (defined $obj->{tags}{'bridge'})?' bridge':'';
  my $stl = "style=\"left:".($obj->{lanes}{offset}+246)."px\"";
  return unless(defined $shoulder);
  if(!$obj->{reversed}) {
    if($shoulder eq 'right' || $shoulder eq 'both' || $obj->{tags}{'shoulder:right'} eq 'yes') {
      $o .= "<div class=\"lane rightshoulder$bridge\">&nbsp;</div>";
      }
    if($shoulder eq 'left' || $shoulder eq 'no') {
      $o .= "<div class=\"lane norightshoulder$bridge\">&nbsp;</div>";
      }
    if($shoulder eq 'left' || $shoulder eq 'both' || $obj->{tags}{'shoulder:left'} eq 'yes') {
      $o .= "<div class=\"lane leftshoulder$bridge\" $stl>&nbsp;</div>";
      }
    if($shoulder eq 'right' || $shoulder eq 'no') {
      $o .= "<div class=\"lane noleftshoulder$bridge\" $stl>&nbsp;</div>";
      }
    }
  else {
    if($shoulder eq 'right' || $shoulder eq 'both' || $obj->{tags}{'shoulder:right'} eq 'yes') {
      $o .= "<div class=\"lane leftshoulder$bridge\" $stl>&nbsp;</div>";
      }
    if($shoulder eq 'left' || $shoulder eq 'no') {
      $o .= "<div class=\"lane noleftshoulder$bridge\" $stl>&nbsp;</div>";
      }
    if($shoulder eq 'left' || $shoulder eq 'both' || $obj->{tags}{'shoulder:left'} eq 'yes') {
      $o .= "<div class=\"lane rightshoulder$bridge\">&nbsp;</div>";
      }
    if($shoulder eq 'right' || $shoulder eq 'no') {
      $o .= "<div class=\"lane norightshoulder$bridge\">&nbsp;</div>";
      }
    }
  return $o;
  }
  
#################################################
## Produce html output to show a way
#################################################  
sub drawWay {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
  my $out = "";
  my $length;
  $totallength += $length = OSMData::calcLength($id);

  OSMLanes::InspectLanes($waydata->{$id});
  my $lanes = $waydata->{$id}{lanes};
  
  my $lat = $nodedata->{$waydata->{$id}{end}}{lat};
  my $lon = $nodedata->{$waydata->{$id}{end}}{lon};  
  my $name = $t->{'name'};
     $name .= "<br>][".$t->{'bridge:name'} if $t->{'bridge:name'};
     $name .= "<br>)(".$t->{'tunnel:name'} if $t->{'tunnel:name'};
     $name .= "&nbsp;" unless $name;
  $out .= '<div class="way">';
  
  $out .= '<div class="middle">&nbsp;</div>' if $placement;
  
  $out .= '<div class="label">';
  $out .= sprintf("km %.1f",$totallength/1000);
  $out .= '<br><a name="'.$id.'" href="https://www.openstreetmap.org/way/'.$id.'" title="'.OSMData::listtags($waydata->{$id}).'">Way '.$id.'</a>';
  $out .= sprintf("<br>%im",$length);
  $out .= sprintf("<br><a target=\"_blank\" href=\"http://www.mapillary.com/map/im/bbox/%.5f/%.5f/%.5f/%.5f\">(M)</a>",$lat-0.005,$lat+0.005,$lon-0.005,$lon+0.005);
  $out .= sprintf("<a target=\"_blank\" href=\"http://127.0.0.1:8111/load_and_zoom?left=%.5f&right=%.5f&top=%.5f&bottom=%.5f&select=way$id\">(J)</a>",$lon-0.01,$lon+0.01,$lat+0.005,$lat-0.005);
  $out .= "</div>\n";
  
  $out .= '<div class="signs">';
  $out .= OSMDraw::makeRef(($t->{'ref'}||''),'');
  $out .= "<div style=\"clear:both;\">$name</div>";

  $out .= OSMDraw::makeMaxspeed($id);
  $out .= "</div>\n";
  
  $out .= '<div class="placeholder" style="width:'.($lanes->{offset}).'px">&nbsp;</div>'."\n";
  

  $waydata->{$id}{lanes}{destinations} = OSMDraw::makeAllDestinations($id,0);
  
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    my $dir    = $lanes->{list}[$i];
    my $turns  = $lanes->{turn}[$i];
    my $max    = $lanes->{maxspeed}[$i];
    my $width  = $lanes->{width}[$i];
    my $access = $lanes->{access}[$i];
    my $change = ($lanes->{change}[$i]||"")." ";
    my $bridge = (defined $t->{'bridge'})?'bridge':'';

    $out .= '<div class="lane '.$dir." ".$change.$bridge.$access.'" ';
    $out .= 'style="width:'.($width*$LANEWIDTH/4-10).'px"' if $lanewidth && $width;
    $out .= '>';
    if($dir ne "nolane") {
      $out .= OSMDraw::makeTurns($turns,$dir);
      if($lanes->{destinations}[$i]) {  
        $out .= $lanes->{destinations}[$i];  
        }
      if($max) {
        $out .= "<div class=\"max ".(($max eq 'none')?'none':'').'">'.(($max eq 'none')?'':$max)."</div>";
        }
      if($access) {
        $out .= "<div class=\"access $access\">&nbsp;</div>";
        }
      if($width && !$lanewidth ) {
        $out .= "<div class=\"width\">&lt;-".(sprintf('%.1f',$width))."-&gt;</div>";
        }
      }
    $out .= '</div>'."\n";
    }
  $out .= OSMDraw::makeShoulder($waydata->{$id});
  
  my $beginnodetags = $nodedata->{$waydata->{$id}{begin}}{'tags'};  
  if(defined $beginnodetags->{highway} && $beginnodetags->{highway} eq "motorway_junction") {
    $out .= '<div class="sep"><div class="name">'.$beginnodetags->{ref}." ".$beginnodetags->{name}.'</div>';
    }
  else {
    $out .= '<div class="sep">&nbsp;';
    }
  
  
  if($adjacent) {
    if(defined $endnodes->[1]{$waydata->{$id}{end}} ) { 
      $out .= OSMDraw::makeWaylayout($id);
      }
    }  
  
  $out .= '</div>';
  $out .= "</div>\n\n";
  return $out;
}
 
  


1;
