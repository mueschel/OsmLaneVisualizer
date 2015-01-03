package OSMDraw;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';
use OSMData;
use OSMLanes;

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
  my ($ref,$dest,$roadref) = @_;
  my $o = "";
  my $cr = "K";
  $ref =~ s/;/ \/ /g;
  if($ref) {
    $cr = "A" if $ref =~ /^A/;
    $cr = "B" if $ref =~ /^B/;
    $o .='<div class="ref'.$cr.'">'.$ref.'</div>';
    }
#   if($cr eq 'K' && $fallbackref) {
#     }
  if($dest) {
    $cr = 'K';
    $cr = "A" if $roadref =~ /^A/;
    $cr = "B" if $roadref =~ /^B/;
    $dest =~ s/;/<br>/g;
    $o .='<div class="'.$cr.'">'.$dest.'</div>';
    }
  return $o;  
  }
  
  
sub getAngleToNext {
  my $id = shift @_;
  my $angle;
  return unless defined $waydata->{$id}{after};
  $angle = OSMData::calcAngle($waydata->{$id}{nodes}[-1],$waydata->{$id}{nodes}[-2],$waydata->{$waydata->{$id}{after}[0]}{nodes}[1]);
  return $angle;
  }

sub getAngleBetween {
  my($from,$to) = @_;
  my $node = 0;
  
  $node = $store->{way}[1]{$to}{nodes}[1]  if $store->{way}[1]{$to}{nodes}[0]  == $waydata->{$from}{nodes}[-1];
  $node = $store->{way}[1]{$to}{nodes}[-2] if $store->{way}[1]{$to}{nodes}[-1] == $waydata->{$from}{nodes}[-1];
  
#   print $waydata->{$from}{nodes}[-1]."/".$waydata->{$from}{nodes}[-2]."/".$node."+";
  my $angle = OSMData::calcAngle($waydata->{$from}{nodes}[-1],$waydata->{$from}{nodes}[-2],$node);
#   print $angle."<br>\n";
  return $angle;
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

  OSMLanes::getLanes($id);
  OSMLanes::getTurn($id);
  OSMLanes::getPlacement($id);
  OSMLanes::getChange($id);
  OSMLanes::getDestinationRef($id);
  OSMLanes::getDestination($id);
  OSMLanes::getMaxspeed($id);
  $out .= '<div class="way">';
  $out .= '<div class="middle">&nbsp;</div>' if $placement;
  $out .= '<div class="label">';
  $out .= sprintf("km %.1f",$totallength/1000);
  $out .= '<br><a href="https://www.openstreetmap.org/way/'.$id.'" title="'.OSMData::listtags($waydata->{$id}).'">Way '.$id.'</a>';
  $out .= sprintf("<br>%im",$length);
  $out .= "</div>\n";
  $out .= '<div class="signs">';
  $out .= OSMDraw::makeDestination(($t->{'ref'}||''),'');
  $out .= "<div style=\"clear:both;\">".($t->{'name'}||'&nbsp;')."</div>";
  $out .= OSMDraw::makeMaxspeed($id);

#   my $angle = OSMDraw::getAngleToNext($id);
#   $out .= '<div class="angle">'.sprintf('%.1f&deg;',$angle).'</div>'."\n"."\n";
  
  $out .= "</div>\n";
  
  $out .= '<div class="placeholder" style="width:'.($lanes->{offset}*100).'px">&nbsp;</div>';
  for(my $i=0; $i < scalar (@{$lanes->{list}});$i++) {
    my $dir   = $lanes->{list}[$i];
    my $turns = $lanes->{turn}[$i];
    my $max   = $lanes->{maxspeed}[$i];
    my $fallbackref;
    $fallbackref = $t->{'ref'}; #if $t->{'destination'} && !$t->{'destination:lanes'};
    my $dest  = OSMDraw::makeDestination($lanes->{destinationref}[$i],$lanes->{destination}[$i],$fallbackref);
    my $change= ($lanes->{change}[$i]||"")." ";
    my $bridge= (defined $t->{'bridge'})?'bridge':'';
    $out .= '<div class="lane '.$dir." ".$change.$bridge.'">';
    if($turns ne "" && $turns ne "none") {
      $turns =~ s/;//g;
      $out .= "<img class='".$dir."' width='60' src='../lanes/img/turn%20forward%20$turns.png'><br>";
      }
    if($dest) {  
      $out .= "<div class=\"destination\">$dest</div>";  
      }
    if($max) {
      $out .= "<div class=\"max ".(($max eq 'none')?'none':'').'">'.(($max eq 'none')?'':$max)."</div>";
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
    if(defined $endnodes->{$waydata->{$id}{end}} ) { 
      $out .= '<div class="waylayout">';
      my $stangle = OSMData::calcDirection($store->{node}[0]{$waydata->{$id}{nodes}[-1]},
                                           $store->{node}[0]{$waydata->{$id}{nodes}[-2]})
                                           -90;
      foreach my $i (@{$endnodes->{$waydata->{$id}{end}}}) {
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