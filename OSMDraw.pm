package OSMDraw;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';
use OSMData;
use OSMLanes;
# use Data::Dumper;
use List::Util qw(min max);
use HTML::Entities;
my $totallength = 0;


#################################################
## Returns one or two symbols for maxspeed, 
## separated forward and backward direction if needed
#################################################
sub makeMaxspeed {
  my $id = shift @_;
  my $item = shift @_;
  my $name = substr($item,0,3);
  my $t = $waydata->{$id}{tags};
  my $out = '';
  
  my $maxforward  = $t->{$item.':forward'}  || $t->{$item} || 'unkwn';
  my $maxbackward = $t->{$item.':backward'} || $t->{$item} || 'unkwn';
  my $fwdclass = $maxforward; my $bckclass = $maxbackward;
  $maxforward =~ s/none//;
  $maxbackward =~ s/none//;
  
  if($maxforward eq $maxbackward) {
    $out = '<div class="'.$name.' '.$fwdclass.'">'.$maxforward.'</div>';
    }
  elsif ($waydata->{$id}{reversed}) {  
    $out  = '<div class="'.$name.' fwd '.$fwdclass.'">'.$maxforward.'</div>';
    $out .= '<div class="'.$name.' bck '.$bckclass.'">'.$maxbackward.'</div>';
    }
  else {
    $out  = '<div class="'.$name.' bck '.$bckclass.'">'.$maxbackward.'</div>';
    $out .= '<div class="'.$name.' fwd '.$fwdclass.'">'.$maxforward.'</div>';
    }
  foreach my $mc (qw(:hgv :hgv:forward :hgv:backward)) {  
    if ($t->{$item.$mc})  {
      $out .= '<div class="maxcont">';
      $out .= '<div class="'.$name.' ">'.($t->{$item.$mc}).'</div>';
      $out .= '<div class="condition hgv">&nbsp;</div>';
      $out .= '</div>';
      }
    }  
  foreach my $mc (qw(:conditional :forward:conditional :backward:conditional)) {   
    if ($t->{$item.$mc})  {
      my $str = $t->{$item.$mc};
      while ($str =~ /([^\(;]+)\s*@\s*(\(([^\)]+)\)|([^;]+))/g) {
        my $what = $1;
        my $when = $3.$4;
        my $title = $1.' @ '.$3.$4;
        my $class;
        $when =~ s/:00//g;
        if($when eq 'wet') {$when = ''; $class="wet";}
        $out .= '<div class="maxcont" title="'.$title.'">';
        $out .= '<div class="'.$name.' ">'.$what.'</div>';
        $out .= '<div class="condition '.$class.'">'.$when.'</div>';
        $out .= '</div>';
        }
      }
    }  
  return $out;
  }

#################################################
## road signs
################################################# 
sub makeSigns {
  my $obj = shift @_;
  my $i   = shift @_;
  my $t;
  my $out;
  if(defined $i) {
    $t->{'access'}  = $obj->{lanes}{access}[$i];
    $t->{'bicycle'} = $obj->{lanes}{bicycle}[$i];
    $t->{'foot'}    = $obj->{lanes}{foot}[$i];
    $t->{'bus'}     = $obj->{lanes}{bus}[$i];
    $t->{'psv'}     = $obj->{lanes}{psv}[$i];
    $t->{'hgv'}     = $obj->{lanes}{hgv}[$i];
    }
  else {
    $t = $obj->{tags};
    }
  if ($t->{'overtaking'} eq "no" || $t->{'overtaking:forward'} eq "no" || $t->{'overtaking:backward'} eq "no") {
    $out .= "<div class=\"overtaking\">&nbsp;</div>";
    }    
  if ($t->{'overtaking:hgv'} eq "no" || $t->{'overtaking:hgv:backward'} eq "no" || $t->{'overtaking:hgv:forward'} eq "no") {
    $out .= "<div class=\"overtakinghgv\">&nbsp;</div>";
    }    
  if ($t->{'bicycle'} eq "no") {
    $out .= "<div class=\"bicycleno\">&nbsp;</div>";
    }
  if ($t->{'bicycle'} eq 'designated' || $t->{'bicycle'} eq 'official') {
    $out .= "<div class=\"bicycledesig\">&nbsp;</div>";
    }
  if ($t->{'foot'} eq "no") {
    $out .= "<div class=\"footno\">&nbsp;</div>";
    }
  if ($t->{'foot'} eq 'designated' || $t->{'foot'} eq 'official') {
    $out .= "<div class=\"footdesig\">&nbsp;</div>";
    }
  if ($t->{'psv'} eq 'designated' || $t->{'psv'} eq 'official') {
    $out .= "<div class=\"busdesig\">&nbsp;</div>";
    $out .= "<div class=\"taxiyes\">&nbsp;</div>";
    }
  if ($t->{'bus'} eq 'designated' || $t->{'bus'} eq 'official') {
    $out .= "<div class=\"busdesig\">&nbsp;</div>";
    }
  if ($t->{'hgv'} eq 'no') {
    $out .= "<div class=\"hgvno\">&nbsp;</div>";
    }
  if ($t->{'hgv'} eq 'designated' || $t->{'hgv'} eq 'official') {
    $out .= "<div class=\"hgvdesig\">&nbsp;</div>";
    }
  if ($t->{'motorroad'} eq "yes") {
    $out .= "<div class=\"motorroad\">&nbsp;</div>";
    }
  if ($t->{'junction'} eq "roundabout") {
    $out .= "<div class=\"roundabout\">&nbsp;</div>";
    }
  return $out;
  }

  
#################################################
## Signs from node tags
#################################################   
sub makeNodeSigns  {
  my $id = shift(@_);
  my $st;my $out = '';
  foreach my $n (@{$waydata->{$id}{nodes}}) {
    next if $n == $waydata->{$id}{begin};
    foreach my $k (keys %{$nodedata->{$n}{tags}}) {
      if($k eq 'highway' && $nodedata->{$n}{tags}{$k} eq 'traffic_signals') {$st->{'traffic_signals'} = 1;}
      if($k eq 'highway' && $nodedata->{$n}{tags}{$k} eq 'give_way') {$st->{'give_way'} = 1;}
      if($k eq 'highway' && $nodedata->{$n}{tags}{$k} eq 'crossing') {$st->{'crossing'} = 1;}
      if($k eq 'highway' && $nodedata->{$n}{tags}{$k} eq 'stop') {$st->{'stop'} = 1;}
      if($k eq 'highway' && $nodedata->{$n}{tags}{$k} eq 'mini_roundabout') {$st->{'roundabout'} = 1;}
      }
    }
  print Dumper $st;  
  foreach my $s (keys %{$st}) {
    $out .= "<div class=\"$s\">&nbsp;</div>"; 
    }
  return $out;  
  }  
  
  
#################################################
## Print a road ref number
#################################################   
sub printRef {
  my $r = shift @_;
  my $cr = "";
  my $o = "";
  if($country eq 'de'){
    $cr = "A" if $r =~ /^\s*A/;
    $cr = "B" if $r =~ /^\s*B/;
    $cr = "E" if $r =~ /^\s*E/;
    $cr = "S" if $r =~ /^\s*S/;
    }
  elsif($country eq 'be') {
    $cr = "N" if $r =~ /^\s*N/;
    $cr = "E" if $r =~ /^\s*E/;
    $cr = "R" if $r =~ /^\s*R/;
    }
  unless($r =~ '^\s*$') {
    $o .='<span class="ref'.$cr.'">'.$r.'</span>';
    }
  return $o;  
  }

  
#################################################
## Format the "ref" of a way
################################################# 
sub makeRef {
  my ($ref) = @_;
  my $o ='';
  if($ref) {
    my $cr;
    $cr = 'K' if $country eq 'de';
    $cr = 'N' if $country eq 'be';
    my @refs = split(';',$ref);
    foreach my $r (@refs) {
      $cr = "A" if $r =~ /^\s*A/;
      $cr = "B" if $r =~ /^\s*B/;
      $cr = "N" if $r =~ /^\s*N/;
      $cr = "E" if $r =~ /^\s*E/;
      $cr = "R" if $r =~ /^\s*R/;
      $cr = "S" if $r =~ /^\s*S/;
      if($r ne '') {
        $o .='<div class="ref'.$cr.'">'.$r.'</div>';
        }
      }
    }
  return $o;
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
  my $refto   = $lanes->{destinationrefto}[$lane];
  my $irefto  = $lanes->{destinationintrefto}[$lane];
  my $to      = $lanes->{destinationto}[$lane];
  my $symbolto= $lanes->{destinationsymbolto}[$lane];
  my $destcol = $lanes->{destinationcolour}[$lane];
  my $destcolto = $lanes->{destinationcolourto}[$lane];
  my $destsym = $lanes->{destinationsymbol}[$lane];
  my $destcountry = $lanes->{destinationcountry}[$lane];
  my $arrow   = $lanes->{destinationarrow}[$lane];
  my $arrowto = $lanes->{destinationarrowto}[$lane];
  my $distance = $lanes->{destinationdistance}[$lane];
  my $titledest = $dest;
  my $signdest  = $dest;

  $ref   =~ s/;/ \/ /g;
  $signdest =~ s/;/<br>/g;
  $titledest =~ s/;/\n/g;  
  $destsym =~ s/none//g;
  $arrow =~ s/none//g;
  
  if($ref || $dest || $destsym || $destcountry || $refto || $to) {
    $o .= '<div class="refcont">';
#     unless($option =~ /notooltip/) {
#       $o .= '<div class="tooltip">'.$ref.'<br>'.$signdest.'</div>';
#       }
    
    $cr = 'K' if $country eq 'de';
    $cr = 'N' if $country eq 'be';
    $cr = "B" if $roadref =~ /^\s*B/;
    $cr = "A" if $roadref =~ /^\s*A/ || $ref =~ /^\s*A/;

    
    $o .='<div class="'.$cr.'" >';
    my @dests  = split(";",$dest,-1);
    my @reftos    = split(";",$refto,-1);
    my @ireftos   = split(";",$irefto,-1);
    my @tos       = split(";",$to,-1);
    my @symboltos = split(";",$symbolto,-1);
    my @cols   = split(";",$destcol,-1);
    my @coltos = split(";",$destcolto,-1);
    my @syms   = split(";",$destsym,-1);
    my @ctr    = split(';',$destcountry,-1);
    my @arro   = split(';',$arrow,-1);
    my @arroto = split(';',$arrowto,-1);
    my @distances = split(';',$distance,-1);

    my $entries = max(scalar @ireftos, scalar @reftos, scalar @tos);
    if($entries > 1) {
      @ireftos = ($ireftos[0]) x $entries if(scalar @ireftos == 1);
      @reftos = ($reftos[0]) x $entries if(scalar @reftos == 1);
      @tos = ($tos[0]) x $entries if(scalar @tos == 1);
      @coltos = ($coltos[0]) x $entries if(scalar @coltos == 1);
      @symboltos = ($symboltos[0]) x $entries if(scalar @symboltos == 1);
      @arroto = ($arroto[0]) x $entries if(scalar @arroto == 1);
      }
    
    for (my $i = 0; $i < $entries; $i++) {
      if($coltos[$i]) {
        my $tc = '';
        if($coltos[$i] eq 'white' || $coltos[$i] =~ /ffffff/) { $tc = 'color:black;';}
        if($coltos[$i] eq 'blue') {$tc = 'color:white';}
        if($coltos[$i] eq 'blue') {$coltos[$i] = '#5078D0';}
        $coltos[$i] = 'style="background-color:'.$coltos[$i].';';
        $coltos[$i] .= $tc.'"';
        }    
      if($symboltos[$i]) {
        if(!$reftos[$i] && !$ireftos[$i] && !$tos[$i]) {$symboltos[$i] .= " symbolonly";}
        else {$symboltos[$i] .= " symbol";}
        }
 
      $symboltos[$i] = "dest refto ".$symboltos[$i];
      $o .= '<div class="'.$symboltos[$i].'">';
      $o .= '<span '.$coltos[$i].'>';
      if($arroto[$i] && $arroto[$i] ne $lanes->{turn}[$lane]) {
        if ($arroto[$i] eq 'left')          {$o .= "<span class='l'>&#x2794;</span> ";}
        if ($arroto[$i] eq 'slight_left')   {$o .= "<span class='sl'>&#x2794;</span> ";}
        if ($arroto[$i] eq 'through')       {$o .= "<span class='t'>&#x2794;</span> ";}
        if ($arroto[$i] eq 'slight_right')  {$tos[$i] = $tos[$i]." <span class='sr'>&#x2794;</span>";}
        if ($arroto[$i] eq 'right')         {$tos[$i] = $tos[$i]." <span class='r'>&#x2794;</span>";}
        } 
      $o .= printRef($reftos[$i].$ireftos[$i]);
      $o .= ($tos[$i]||"&nbsp;").'</span>';
      $o .= '</div>';
      } 

    $entries = max(scalar @dests,scalar @syms);
    if($entries > 1) {
      @cols = ($cols[0]) x $entries if(scalar @cols == 1);
      @syms = ($syms[0]) x $entries if(scalar @syms == 1);
      @arro = ($arro[0]) x $entries if(scalar @arro == 1);
      @distances = ($distances[0]) x $entries if(scalar @distances == 1);
      }
      
    for (my $i = 0; $i < $entries; $i++ ) {
      if($cols[$i]) {
        my $tc = '';
        if($cols[$i] eq 'white' || $cols[$i] =~ /ffffff/) { $tc = 'color:black;';}
        if($cols[$i] eq 'blue') {$tc = 'color:white';}
        if($cols[$i] eq 'blue') {$cols[$i] = '#5078D0';}
        $cols[$i] = 'style="background-color:'.$cols[$i].';';
        $cols[$i] .= $tc.'"';
        }
      if($syms[$i]) {
        if(!$dests[$i]) {$syms[$i] .= " symbolonly";}
        else {$syms[$i] .= " symbol";}
        }
      $syms[$i] = "dest ".$syms[$i];
      $o .= '<div class="'.$syms[$i].'">';
      $o .= '<span '.$cols[$i].'>';
      if($distances[$i]) {
        $dests[$i] .= "  ".$distances[$i];
        $dests[$i] .= " km" if !($distances[$i] =~ /(mi|nmi|km|m|\")/);
        }

      if($arro[$i] && $arro[$i] ne $lanes->{turn}[$lane]) {
        if ($arro[$i] eq 'left')          {$o .= "<span class='l'>&#x2794;</span> ";}
        if ($arro[$i] eq 'slight_left')   {$o .= "<span class='sl'>&#x2794;</span> ";}
        if ($arro[$i] eq 'through')       {$o .= "<span class='t'>&#x2794;</span> ";}
        if ($arro[$i] eq 'slight_right')  {$dests[$i] = $dests[$i]." <span class='sr'>&#x2794;</span>";}
        if ($arro[$i] eq 'right')         {$dests[$i] = $dests[$i]." <span class='r'>&#x2794;</span>";}
        }       
      $o .= ($dests[$i]||"&nbsp;");
      $o .= '<span class="destCountry">'.$ctr[$i].'</span>' if(scalar @ctr == scalar @dests && $ctr[$i] ne 'none' && $ctr[$i]);
      $o .= '</span>';
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
        $o .= printRef($r);
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
  my $correspondingid = shift @_;
  my $t;
  my $lanes;
  
  $t = $store->{way}[$st]{$id}{tags};
  $lanes = $store->{way}[$st]{$id}{lanes};
  my $tilt = -($store->{way}[$st]{$correspondingid || $id}{lanes}->{tilt}||0);
  
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
      @destinations[$i] = '<div class="destination '.$w.'"  style="transform:skewX('.$tilt.'deg)">'.@destinations[$i].'</div>';  
      }
    } 
  return \@destinations;
  }
  
  
#################################################
## In case the way splits, the best choice is the one with the smallest turning angle. Despite on roundabouts...
#################################################
sub getBestNext {  
  my $id = shift @_;
  my $angle = 0;
  my $ra = 0;
  my $minangle = 180;
  my $realnext;
  my $fromdirection = OSMData::calcDirection($nodedata->{$waydata->{$id}{nodes}[-1]},$nodedata->{$waydata->{$id}{nodes}[-2]});
  
  if($waydata->{$id}{tags}{'junction'} eq 'roundabout') {
    $ra = 1;
    $minangle = 0;
    }
    
  return unless defined $waydata->{$id}{after};
  foreach my $nx (@{$waydata->{$id}{after}}) {
    if($nodedata->{$waydata->{$nx}{nodes}[0]} == $nodedata->{$waydata->{$id}{nodes}[-1]}) {
      $angle = OSMData::calcDirection($nodedata->{$waydata->{$nx}{nodes}[1]},$nodedata->{$waydata->{$nx}{nodes}[0]});
      }
    else {
      $angle = OSMData::calcDirection($nodedata->{$waydata->{$nx}{nodes}[-2]},$nodedata->{$waydata->{$nx}{nodes}[-1]});
      }
    
    $angle = ($fromdirection-$angle);
    $angle = OSMData::NormalizeAngle($angle);
    $angle = abs($angle);
    #print "$id $nx $angle<br>";
    if(($ra == 0 && $angle < $minangle) || ($ra == 1 && $angle > $minangle)) {
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
  my $next = shift @_;
  my $out = "";
  my $cntways = 0;
  my $connectsangle = -400;
  my $connectsid = 0;
  $out .= '<div class="waylayout">';
  my $stangle = OSMData::calcDirection($store->{node}[0]{$waydata->{$id}{nodes}[-1]},
                                        $store->{node}[0]{$waydata->{$id}{nodes}[-2]})
                                        -90;
  $stangle = 0;                                        
  foreach my $i (@{$endnodes->[1]{$waydata->{$id}{end}}}) {
    my $nd = 0;
    $nd = $store->{way}[1]{$i}{nodes}[1]     if ($store->{way}[1]{$i}{nodes}[0] == $waydata->{$id}{end});
    $nd = $store->{way}[1]{$i}{nodes}[-2]    if ($store->{way}[1]{$i}{nodes}[-1] == $waydata->{$id}{end});
    my $angle = sprintf("%.1f",OSMData::NormalizeAngle(OSMData::calcDirection($store->{node}[1]{$waydata->{$id}{end}},$store->{node}[1]{$nd})-$stangle));
    my $main =  (defined $waydata->{$i})?'main':'';
    $main =  'next' if $i == $next;
    my $direction = "toward";
    if ($store->{way}[1]{$i}{nodes}[0] == $waydata->{$id}{end} && (!(exists $store->{way}[1]{$i}{tags}{"oneway"}) || $store->{way}[1]{$i}{tags}{"oneway"} ne "-1")) {
      $direction = "away";
      }
    elsif ($store->{way}[1]{$i}{nodes}[-1] == $waydata->{$id}{end} && (!(exists $store->{way}[1]{$i}{tags}{"oneway"}) || $store->{way}[1]{$i}{tags}{"oneway"} eq "-1")) {
      $direction = "away";
      }

    if($main) {
      my $from = ($i == $id)?'from':'';
      $out .= '<div class="connects '.$main.' '.$from.'" style="transform:rotate('.$angle.'deg)">&nbsp;</div>';
      }
    else {
      my $title = OSMData::listtags($store->{way}[1]{$i});
      $cntways++;
      $connectsangle = $angle;
      $connectsid = $i;
      $out .= '<a href="https://www.openstreetmap.org/way/'.$i.'" target="_blank"><div class="connects'.' '.$direction.'" style="transform:rotate('.$angle.'deg)" title="Way '.$i."\n".$title.'" >&nbsp;</div></a>';
      }
    }
  $out .= '</div>';
  
  if(scalar @{$endnodes->[1]{$waydata->{$id}{end}}} >= 3 && $cntways == 1 && (($connectsangle > -160 && $connectsangle < -20) || $connectsangle > 200)) { #if only one way and in forward direction
    OSMLanes::InspectLanes($store->{way}[1]{$connectsid});
    
    $out .= '<div class="connectdestination">';
    my $d = OSMDraw::makeAllDestinations($connectsid,1,'notooltip',$id);
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
  my $obj = $waydata->{shift @_};
  my $side = shift @_;
  my $o = '';
  my $shoulder = $obj->{tags}{'shoulder'};

  if(!$obj->{reversed}) {
    if($side eq 'right') {
      if($shoulder eq 'right' || $shoulder eq 'both' || $obj->{tags}{'shoulder:right'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\">&nbsp;</div>";
        }
      if((((defined $shoulder && $shoulder ne 'right' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:right'} ne 'yes') || $obj->{tags}{'shoulder:right'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\" >&nbsp;</div>";
        }
      }
    else {  
      if((((defined $shoulder && $shoulder ne 'left' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:left'} ne 'yes') || $obj->{tags}{'shoulder:left'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\">&nbsp;</div>";
        $obj->{lanes}{offset} -= 4;
        }
      if($shoulder eq 'left' || $shoulder eq 'both' || $obj->{tags}{'shoulder:left'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\" >&nbsp;</div>";
        $obj->{lanes}{offset} -= $LANEWIDTH*0.6;
        }
      }
    }
  else {
    if($side eq 'right') {
      if((((defined $shoulder && $shoulder ne 'left' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:left'} ne 'yes') || $obj->{tags}{'shoulder:left'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\" >&nbsp;</div>";
        }
      if($shoulder eq 'left' || $shoulder eq 'both' || $obj->{tags}{'shoulder:left'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\">&nbsp;</div>";
        }
      }  
    else {
      if($shoulder eq 'right' || $shoulder eq 'both' || $obj->{tags}{'shoulder:right'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\" >&nbsp;</div>";
        $obj->{lanes}{offset} -= $LANEWIDTH*0.6;
        }
      if((((defined $shoulder && $shoulder ne 'right' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:right'} ne 'yes') || $obj->{tags}{'shoulder:right'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\">&nbsp;</div>";
        $obj->{lanes}{offset} -= 4;
        }
      }  
    }
  return $o;
  }

#################################################
## draws sidewalks
#################################################    
sub makeSidewalk {
  my $obj = $waydata->{shift @_};
  my $side = shift @_;
  my $o = '';
  my $sidewalk = $obj->{tags}{'sidewalk'};

  my $l=""; my $r="";
  if($sidewalk eq "no" || $sidewalk eq "none") {$l = "nosidewalk";    $r = "nosidewalk"; }
  elsif($sidewalk eq "left") {$l = "sidewalk";    $r = "nosidewalk"; }
  elsif($sidewalk eq "right") {$l = "nosidewalk";    $r = "sidewalk"; }
  elsif($sidewalk eq "both") {$l = "sidewalk";    $r = "sidewalk"; }
  elsif(defined $sidewalk)  {$l = "nosidewalk";    $r = "nosidewalk"; }
  
  if(($obj->{tags}{'sidewalk:left'}// '') eq 'yes') {$l = "sidewalk";}
  if(($obj->{tags}{'sidewalk:right'}// '') eq 'yes') {$r = "sidewalk";}
  if(($obj->{tags}{'sidewalk:both'}// '') eq 'yes') {$r = "sidewalk";$l = "sidewalk";}
  
  
  my $swlwidth = 4; my $swrwidth = 4;
  $swlwidth = $LANEWIDTH/2 unless $l =~ /^no/;
  $swrwidth = $LANEWIDTH/2 unless $r =~ /^no/;
  if (defined $obj->{tags}{'sidewalk:width'} || defined $obj->{tags}{'sidewalk:left:width'} || defined $obj->{tags}{'sidewalk:both:width'}) {
    $swlwidth = $LANEWIDTH/4*($obj->{tags}{'sidewalk:left:width'} || $obj->{tags}{'sidewalk:both:width'} || $obj->{tags}{'sidewalk:width'}) unless  $l =~ /^no/;
    }
  if (defined $obj->{tags}{'sidewalk:width'} || defined $obj->{tags}{'sidewalk:right:width'} || defined $obj->{tags}{'sidewalk:both:width'}) {
    $swrwidth = $LANEWIDTH/4*($obj->{tags}{'sidewalk:right:width'} || $obj->{tags}{'sidewalk:both:width'} || $obj->{tags}{'sidewalk:width'}) unless  $r =~ /^no/;
    }
  
  
  if($r && (($side eq 'right' && !$obj->{reversed}) || ($side eq 'left' && $obj->{reversed}))) {
    $o .= "<div class=\"lane $r\" style='width:".$swrwidth."px;' >&nbsp;</div>";
    }
  elsif($l && (($side eq 'left' && !$obj->{reversed}) || ($side eq 'right' && $obj->{reversed}))) {
    $o .= "<div class=\"lane $l\" style='width:".$swlwidth."px;'>&nbsp;</div>";
    }
    
  if($r && $obj->{reversed} && $side eq 'right') {  
    $obj->{lanes}{offset} -= $swrwidth;#  unless($r =~ /^no/) ;
#     $obj->{lanes}{offset} -= 4   if($r =~ /^no/) ;
    }
  if($l && !$obj->{reversed} && $side eq 'left') {  
    $obj->{lanes}{offset} -= $swlwidth;#  unless($l =~ /^no/) ;
#     $obj->{lanes}{offset} -= 4   if($l =~ /^no/) ;
    }
  
  return $o;  
  }

  
#################################################
## JS code for map update
#################################################   
sub generateMapJS  {
  my $id = shift @_;
  my $lat = $nodedata->{$waydata->{$id}{begin}}{lat};
  my $lon = $nodedata->{$waydata->{$id}{begin}}{lon};  
  my $str = "";
#   $str .= 'map.setView(['.$lat.', '.$lon.'], 17)';
  $str .= 'map.removeLayer(marker);'; 
  $str .= 'marker = L.marker(['.$lat.', '.$lon.']).addTo(map);';
  my $list = "";
  foreach my $n (@{$waydata->{$id}{nodes}}) {
    $list .= "[".$nodedata->{$n}{lat}.", ".$nodedata->{$n}{lon}."],"
    }
  chop $list;
  $str .= 'map.removeLayer(polyline);';
  $str .= 'polyline = L.polyline(['.$list.'], {color: \'#44f\'}).addTo(map);';
  $str .= 'map.fitBounds(polyline.getBounds());';
  return $str;
  
}


#################################################
## Continuation links top/bottom of page
################################################# 
sub linkWay {
  my $id = shift @_;
  my $arrow = shift @_;
  my $style = shift @_ || "navigation";
  return unless $extendway;
  $arrow = "&#9650;" if $arrow eq "up";
  $arrow = "&#9660;" if $arrow eq "down";
  my $str = "";
  $str .= '<span class="'.$style.'" href="" onClick="changeURL(\'wayid\',\''.$id.'\')">'.$arrow.'</span>';
  return $str;
  
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
  
  my $lat = $nodedata->{$waydata->{$id}{begin}}{lat};
  my $lon = $nodedata->{$waydata->{$id}{begin}}{lon};  
  my $name = $t->{'name'};
     $name .= "<br>][ ".$t->{'bridge:name'} if $t->{'bridge:name'};
     $name .= "<br>)( ".$t->{'tunnel:name'} if $t->{'tunnel:name'};
     $name .= "&nbsp;" unless $name;
  $out .= '<div class="way" >';
  
  $out .= '<div class="middle">&nbsp;</div>' if $USEplacement;
  
  $out .= '<div class="label" onMouseOver="'.generateMapJS($id).'">';
  $out .= sprintf("km %.1f",$totallength/1000);
  $out .= '<br><a name="'.$id.'" href="https://www.openstreetmap.org/way/'.$id.'" title="'.OSMData::listtags($waydata->{$id}).'" >Way '.$id.'</a>';
  $out .= sprintf("<br>%im",$length);
  $out .= sprintf("<br><a title=\"view on Mapillary\" target=\"_blank\" href=\"http://www.mapillary.com/app/?lat=%.5f&lng=%.5f&z=16\">(M)</a>",$lat,$lon);
  $out .= sprintf(" <a title=\"load in external editor\" target=\"_blank\" href=\"http://127.0.0.1:8111/load_and_zoom?left=%.5f&right=%.5f&top=%.5f&bottom=%.5f&select=way$id\">(J)</a>",$lon-0.01,$lon+0.01,$lat+0.005,$lat-0.005);
  $out .= " <a title=\"load in level0 editor\" target=\"_blank\" href=\"http://level0.osmz.ru/?url=way/$id!\">(L)</a>\n";
  $out .= linkWay($id,"(V)",'normal');
  $out .= "</div>\n";
  
  $out .= '<div class="info">';
  $out .= OSMDraw::makeRef(($t->{'ref'}||'').';'.($t->{'int_ref'}||''),'');
  $out .= "<div style=\"clear:both;width:100%\">$name</div>";
  $out .= "<div class=\"signs\">";
  $out .= OSMDraw::makeMaxspeed($id,'maxspeed');
  $out .= OSMDraw::makeMaxspeed($id,'minspeed');
  $out .= OSMDraw::makeSigns($waydata->{$id},undef);
  if($usenodes) {
    $out .= OSMDraw::makeNodeSigns($id);
    }
  $out .= "</div></div>\n";

  my $bridge = ((defined $t->{'bridge'})?'bridge':'').((defined $t->{'tunnel'})?' tunnel':'');
 


  $waydata->{$id}{lanes}{destinations} = OSMDraw::makeAllDestinations($id,0);
  
  my @outputlanes;
  
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    my $dir    = $lanes->{list}[$i];
    my $turns  = $lanes->{turn}[$i];
    my $max    = $lanes->{maxspeed}[$i];
    my $min    = $lanes->{minspeed}[$i];
    my $width  = $lanes->{width}[$i];
    my $access = $lanes->{access}[$i];
    my $change = ($lanes->{change}[$i]||"")." ";
    my $o;

    
    $o .= '<div class="lane '.$dir." ".$change.$access.'" ';
    $o .= 'style="width:'.($width*$LANEWIDTH/4-$STROKEWIDTH*2).'px"' if $lanewidth && $width;
    $o .= '>';
    if($dir ne "nolane") {
      $o .= OSMDraw::makeTurns($turns,$dir);
      if($lanes->{destinations}[$i]) {  
        $o .= $lanes->{destinations}[$i];  
        }
      $o .= "<div class=\"signs\" style=\"transform:skewX(-".($lanes->{tilt}||0)."deg)\">";
      if($max) {
        $o .= "<div class=\"max ".(($max eq 'none')?'none':'').'">'.(($max eq 'none')?'':$max)."</div>";
        }
      if($min && $min ne 'none') {
        $o .= "<div class=\"min\">$min</div>";
        }
      $o .= OSMDraw::makeSigns($waydata->{$id},$i);
      $o .= "</div>";
      if($width && !$lanewidth ) {
        $o .= "<div class=\"width\">&#x21E0;".(sprintf('%.1f',$width))."&#x21E2;</div>";
        }
      }
    $o .= '</div>';
    push(@outputlanes,$o);
    }
    
  unshift(@outputlanes,OSMDraw::makeShoulder($id,'left'));
  push   (@outputlanes,OSMDraw::makeShoulder($id,'right'));

  unshift(@outputlanes,OSMDraw::makeSidewalk($id,'left'));
  push   (@outputlanes,OSMDraw::makeSidewalk($id,'right'));
  
  $out .= '<div class="placeholder '.$bridge.'" style="transform:skewX('.($lanes->{tilt}||0).'deg);margin-left:'.($lanes->{offset}).'px">'."\n";
  $out .= join("\n",@outputlanes);
  $out .= "</div>";#placeholder
  
  my $beginnodetags = $nodedata->{$waydata->{$id}{begin}}{'tags'};  
  if(defined $beginnodetags->{highway} && $beginnodetags->{highway} eq "motorway_junction") {
    $out .= '<div class="sep"><div class="name">'.$beginnodetags->{ref}." ".$beginnodetags->{name}.'</div>';
    }
  else {
    $out .= '<div class="sep">&nbsp;';
    }
  
  
  if($adjacent) {
    if(defined $endnodes->[1]{$waydata->{$id}{end}} ) { 
      $out .= OSMDraw::makeWaylayout($id, getBestNext($id));
      }
    }  

  
  $out .= '</div>';
  $out .= "</div>\n\n";
  return $out;
}
 
  


1;
