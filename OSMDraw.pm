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
  my $out = ""; my $fwd = ""; my $bck = "";
  my $value = "";
  my $none = 0;
  
  if (defined $t->{'maxspeed'} && !defined $t->{'maxspeed:forward'}) {
    if($t->{'maxspeed'} eq 'none') { $value = "&nbsp;"; $none = 1;}
      else {$value = $t->{'maxspeed'}; $none = 0;}
    $fwd .= '<div class="max '.($none?'none':'').'">'.$value."</div>";
    }
  elsif (defined $t->{'maxspeed:forward'}) {
    if($t->{'maxspeed:forward'} eq 'none') { $value = "&nbsp;"; $none = 1;}
      else {$value = $t->{'maxspeed:forward'}; $none = 0;}
    $fwd .= '<div class="max '.($none?'none':'').'">'.$value."</div>";
    }    
  if (defined $t->{'maxspeed:backward'}) {
    if($t->{'maxspeed:backward'} eq 'none') { $value = "&nbsp;"; $none = 1;}
      else {$value = $t->{'maxspeed:backward'}; $none = 0;}
    $bck .= '<div class="max '.($none?'none':'').'">'.$value."</div>";
    }
  elsif (defined $t->{'maxspeed'} && defined $t->{'maxspeed:forward'}) {
    if($t->{'maxspeed'} eq 'none') { $value = "&nbsp;"; $none = 1;}
      else {$value = $t->{'maxspeed'}; $none = 0;}
    $bck .= '<div class="max '.($none?'none':'').'">'.$value."</div>";
    }
  return $bck.$fwd if $waydata->{$id}{reversed};
  return $fwd.$bck;
}
  
  
sub makeDestination {
  my ($lane,$way) = @_;
#   my ($ref,$dest,$roadref,$destcol,$destsym) = @_;
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
  $o .= '<div class="refcont"><div class="tooltip">';
  $o .= $ref.'<br>'.$signdest.'</div>';
  if($ref || $dest || ($destsym && $destsym ne "none")) {
    $cr = 'K';
    $cr = "B" if $roadref =~ /^B/;
    $cr = "A" if $roadref =~ /^A/ || $ref =~ /^A/;
    $destsym =~ s/none//g;
    $o .='<div class="'.$cr.'" >';
    if($destcol || $destsym) {
      my @dests = split(";",$dest);
      my @cols  = split(";",$destcol);
      my @syms  = split(";",$destsym);
      for (my $i = 0; $i < max(scalar @dests,scalar @syms); $i++ ) {
        my $tc = '';
        if($cols[$i] eq 'white' || $cols[$i] =~ /ffffff/) { $tc = 'color:black;';}
        if($cols[$i] eq 'blue') {$tc = 'color:white';}
        if($syms[$i]) {
          if(!$dests[$i]) {$syms[$i] .= " symbolonly";}
          else {$syms[$i] .= " symbol";}
          }
        $syms[$i] = "dest ".$syms[$i];
        $o .= '<div class="'.$syms[$i].'" style="background-color:'.$cols[$i].';'.$tc.'">'.($dests[$i]||"&nbsp;").'</div>';
        }
      }
    else {
      $o .= $signdest;
      }
    }
  $o .= '<div class="clear">&nbsp;</div>';  
  if($destcountry) {
    my @ctr = split(';',$destcountry);
    foreach my $c (@ctr) {
      next if $c eq 'none';
      $o .= '<div class="destCountry">'.$c.'</div>';
      }
    }
  if($ref) {
    my @refs = split('/',$ref);
    foreach my $r (reverse @refs) {
      $cr = "A" if $r =~ /^A/;
      $cr = "B" if $r =~ /^B/;
      $o .='<div class="ref'.$cr.'">'.$r.'</div>';
      }
    }  
  $o .= "</div></div>";  
  return $o;  
  }
  

sub makeRef {
  my ($ref) = @_;
  my $o ='';# = '<div class="refcont">';
  if($ref) {
    my $cr = 'K';
    my @refs = split(';',$ref);
    foreach my $r (reverse @refs) {
      $cr = "A" if $r =~ /^A/;
      $cr = "B" if $r =~ /^B/;
      $o .='<div class="ref'.$cr.'">'.$r.'</div>';
      }
    #my $o .= "</div>";
    }
  return $o;
  }
  
# sub getAngleToNext {
#   my $id = shift @_;
#   my $cnt = shift @_;
#   my $angle;
#   return unless defined $waydata->{$id}{after};
#   $angle = OSMData::calcAngle($waydata->{$id}{nodes}[-1],$waydata->{$id}{nodes}[-2],$waydata->{$waydata->{$id}{after}[$cnt]}{nodes}[1]);
#   return $angle;
#   }

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
    $angle += 360 if $angle < -180;
    $angle -= 360 if $angle >  180;
    $angle = abs($angle);
    if($angle < $minangle) {
      $minangle = $angle;
      $realnext = $nx;
      }
    }
  return $realnext;  
  }
  
# sub getAngleBetween {
#   my($from,$to) = @_;
#   my $node = 0;
#   
#   $node = $store->{way}[1]{$to}{nodes}[1]  if $store->{way}[1]{$to}{nodes}[0]  == $waydata->{$from}{nodes}[-1];
#   $node = $store->{way}[1]{$to}{nodes}[-2] if $store->{way}[1]{$to}{nodes}[-1] == $waydata->{$from}{nodes}[-1];
#   
# #   print $waydata->{$from}{nodes}[-1]."/".$waydata->{$from}{nodes}[-2]."/".$node."+";
#   my $angle = OSMData::calcAngle($waydata->{$from}{nodes}[-1],$waydata->{$from}{nodes}[-2],$node);
# #   print $angle."<br>\n";
#   return $angle;
#   }

sub makeTurns {
  my $t = ';'.shift @_;
  my $dir = shift @_;
  my $o = "";
#   $t =~ s/;//g;
#   $o .= "<img class='".$dir."' width='60' src='../lanes/img/turn%20forward%20$t.png'><br>";  

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
## Produce html output to show a way
#################################################  
sub drawWay {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
  my $out = "";
  my $length;
  $totallength += $length = OSMData::calcLength($id);

  OSMLanes::resetLanes();
  OSMLanes::getLanes($id);
  OSMLanes::getTurn($id);
  OSMLanes::getWidth($id);
  OSMLanes::getPlacement($id);
  OSMLanes::getChange($id);
  OSMLanes::getDestinationRef($id);
  OSMLanes::getDestination($id);
  OSMLanes::getMaxspeed($id);
  OSMLanes::getDestinationColour($id);
  OSMLanes::getDestinationSymbol($id);
  OSMLanes::getDestinationCountry($id);
  
  $out .= '<div class="way">';
  $out .= '<div class="middle">&nbsp;</div>' if $placement;
  $out .= '<div class="label">';
  $out .= sprintf("km %.1f",$totallength/1000);
  $out .= '<br><a name="'.$id.'" href="https://www.openstreetmap.org/way/'.$id.'" title="'.OSMData::listtags($waydata->{$id}).'">Way '.$id.'</a>';
  $out .= sprintf("<br>%im",$length);
  $out .= "</div>\n";
  $out .= '<div class="signs">';
  $out .= OSMDraw::makeRef(($t->{'ref'}||''),'');
  $out .= "<div style=\"clear:both;\">".($t->{'name'}||'&nbsp;')."</div>";
  $out .= OSMDraw::makeMaxspeed($id);


  $out .= "</div>\n";
  
  $out .= '<div class="placeholder" style="width:'.($lanes->{offset}).'px">&nbsp;</div>';
  for(my $i=0; $i < scalar (@{$lanes->{list}});$i++) {
    my $dir   = $lanes->{list}[$i];
    my $turns = $lanes->{turn}[$i];
    my $max   = $lanes->{maxspeed}[$i];
    my $width = $lanes->{width}[$i];
    my $fallbackref;
    $fallbackref = $t->{'ref'}; #if $t->{'destination'} && !$t->{'destination:lanes'};
    my $dest  = OSMDraw::makeDestination($i,$t);
    my $change= ($lanes->{change}[$i]||"")." ";
    my $bridge= (defined $t->{'bridge'})?'bridge':'';
    $out .= '<div class="lane '.$dir." ".$change.$bridge.'" ';
    $out .= 'style="width:'.($width*$LANEWIDTH/4-10).'px"' if $lanewidth && $width;
    $out .= '>';
    $out .= OSMDraw::makeTurns($turns,$dir);
    if($dest) {  
      $out .= "<div class=\"destination\">$dest</div>";  
      }
    if($max) {
      $out .= "<div class=\"max ".(($max eq 'none')?'none':'').'">'.(($max eq 'none')?'':$max)."</div>";
      }
    if($width) {
      $out .= "<div class=\"width\">&lt;-".(sprintf('%.1f',$width))."-&gt;</div>";
      }
      
    $out .= '</div>'."\n";
    }
    
    
  my $beginnodetags = $nodedata->{$waydata->{$id}{begin}}{'tags'};  
  if(defined $beginnodetags->{highway} && $beginnodetags->{highway} eq "motorway_junction") {
    $out .= '<div class="sep"><div class="name">'.$beginnodetags->{ref}." ".$beginnodetags->{name}.'</div>';
    }
  else {
    $out .= '<div class="sep">&nbsp;';
    }
  
  
  if($adjacent) {
    if(defined $endnodes->[1]{$waydata->{$id}{end}} ) { 
      $out .= '<div class="waylayout">';
      my $stangle = OSMData::calcDirection($store->{node}[0]{$waydata->{$id}{nodes}[-1]},
                                           $store->{node}[0]{$waydata->{$id}{nodes}[-2]})
                                           -90;
      foreach my $i (@{$endnodes->[1]{$waydata->{$id}{end}}}) {
        my $nd = 0;
        $nd = $store->{way}[1]{$i}{nodes}[1]     if ($store->{way}[1]{$i}{nodes}[0] == $waydata->{$id}{end});
        $nd = $store->{way}[1]{$i}{nodes}[-2]    if ($store->{way}[1]{$i}{nodes}[-1] == $waydata->{$id}{end});
        my $angle = sprintf("%.1f",OSMData::calcDirection($store->{node}[1]{$waydata->{$id}{end}},$store->{node}[1]{$nd})-$stangle);
        my $main =  (defined $waydata->{$i})?'main':'';
        if($main) {
          my $from = ($i == $id)?'from':'';
          $out .= '<div class="connects '.$main.' '.$from.'" style="transform:rotate('.$angle.'deg)">&nbsp;</div>';
          }
        else {
          my $title = OSMData::listtags($store->{way}[1]{$i});
          $out .= '<a href="https://www.openstreetmap.org/way/'.$i.'" target="_blank"><div class="connects" style="transform:rotate('.$angle.'deg)" title="Way '.$i."\n".$title.'" >&nbsp;</div></a>';
          }
        }
      $out .= '</div>';
      }
    }  
  
  $out .= '</div>';
  $out .= "</div>\n\n";
  return $out;
}
 
  


1;