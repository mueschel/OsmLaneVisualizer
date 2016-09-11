package OSMLanes;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';
use Data::Dumper;
use OSMData;
use List::Util qw(min max);
use Math::Trig;
 
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw($LANEHEIGHT $extendway $lanes $maxlanes $USEplacement $adjacent $lanewidth $extrasize $usenodes $LANEWIDTH $STROKEWIDTH);

our $LANEWIDTH = 120;
our $LANEHEIGHT = 135;
our $STROKEWIDTH = 3;
our $lanes;
our $USEplacement = 0;
our $maxlanes = 4;
our $adjacent = 0;
our $lanewidth = 0;
our $usenodes = 0;
our $extrasize = 0;
our $extendway = 0;

#################################################
## Read and interpret number of lanes
#################################################  
sub getLanes {
  my $obj = shift @_;
  my $t = $obj->{tags};
  my @lanedir;
  my $fwdlane = 0; my $bcklane = 0; my $nolane = 0; my $bothlane = 0; my $totlane = 0;

  #Compare number of lanes from different tags
  my $st;

  $st->{id} = $obj->{id};
  foreach my $k (keys %{$t}) {
    if($k =~ /:lanes/) {
      my $c = 1;
      $c++ while ($t->{$k} =~ m/\|/g);
      
      if($k =~ /:forward/)      {push(@{$st->{f}},$c);}
      elsif($k =~ /:backward/)  {push(@{$st->{b}},$c);}
      elsif($k =~ /:both_ways/) {push(@{$st->{m}},$c);}
      else                      {push(@{$st->{l}},$c);}
      }
    }
    
  push(@{$st->{f}},$t->{'lanes:forward'});
  push(@{$st->{b}},$t->{'lanes:backward'});
  push(@{$st->{m}},$t->{'lanes:both_ways'});
  push(@{$st->{l}},$t->{'lanes'});
  
  if(defined $t->{'lanes:forward'} && defined $t->{'lanes'} && ! defined $t->{'lanes:backward'}) {
    push(@{$st->{b}},$t->{'lanes'} - $t->{'lanes:forward'});
    }
  if(defined $t->{'lanes:backward'} && defined $t->{'lanes'} && ! defined $t->{'lanes:forward'}) {
    push(@{$st->{f}},$t->{'lanes'} - $t->{'lanes:backward'});
    }
  
  if(defined max(@{$st->{f}}) && defined max(@{$st->{l}}) && !defined defined max(@{$st->{b}})) {
    push(@{$st->{b}},max(@{$st->{l}})-max(@{$st->{f}}));
    }
  if(defined max(@{$st->{b}}) && defined max(@{$st->{l}}) && !defined defined max(@{$st->{f}})) {
    push(@{$st->{f}},max(@{$st->{l}})-max(@{$st->{b}}));
    }
  
  if(defined $t->{'oneway'} && $t->{'oneway'} ne "no") {
    push(@{$st->{f}},$t->{'lanes'});
    }
  else {
    push(@{$st->{f}},$t->{'lanes'}/2) unless defined max(@{$st->{f}});
    push(@{$st->{b}},$t->{'lanes'}/2) unless defined max(@{$st->{b}});
    }
  
  if(defined $t->{'oneway'} && $t->{'oneway'} ne "no") {
    push(@{$st->{f}},1);
    push(@{$st->{f}},@{$st->{l}});
    }
  else {
    push(@{$st->{f}},1);
    push(@{$st->{b}},1);
    }
    
  $fwdlane  = max(@{$st->{f}}) || 0;
  $bcklane  = max(@{$st->{b}}) || 0;
  $bothlane = max(@{$st->{m}}) || 0;
  $totlane  = max(@{$st->{l}}) || 0;   

  if(defined $t->{'traffic_calming'} && $t->{'traffic_calming'} eq 'island') {
    $nolane = 1;
    }
  
  if(defined $t->{'lanes'} && $t->{'lanes'} > $fwdlane + $bcklane) {
    $nolane = $t->{'lanes'} - $fwdlane - $bcklane;
    }
#   print Dumper $st;   
#   print $fwdlane." ".$bcklane." ".$bothlane."\n";

  if(!$obj->{reversed}) {
    for(my $i=0; $i<$bcklane;$i++)  {push(@lanedir,'backward');}
    for(my $i=0; $i<$bothlane;$i++) {push(@lanedir,'bothlane');}
    for(my $i=0; $i<$nolane;$i++)   {push(@lanedir,'nolane');}
    for(my $i=0; $i<$fwdlane;$i++)  {push(@lanedir,'forward');}
    }
  else {
    for(my $i=0; $i<$fwdlane;$i++)  {push(@lanedir,'backward');}
    for(my $i=0; $i<$bothlane;$i++) {push(@lanedir,'bothlane');}
    for(my $i=0; $i<$nolane;$i++)   {push(@lanedir,'nolane');}
    for(my $i=0; $i<$bcklane;$i++)  {push(@lanedir,'forward');}
    }

  $obj->{lanes}{fwd}  = $fwdlane;
  $obj->{lanes}{bck}  = $bcklane;
  $obj->{lanes}{both} = $bothlane;
  $obj->{lanes}{none} = $nolane;
  $obj->{lanes}{list} = \@lanedir;
  $obj->{lanes}{numlanes} = scalar @lanedir;

  }


#################################################
## generic reader for :lanes tagging
#################################################  
sub getLaneTags {
  my $obj = shift @_;
  my $tag = shift @_;
  my $options = shift @_;
  my $t = $obj->{tags};
  my $lanes = $obj->{lanes};
  my @out;
  
  push(@out,'') for 0..$lanes->{numlanes}-1;
  
  if(defined $t->{$tag} && !($options =~ /nonolanes/))   {
    $out[$_] = $t->{$tag}  for 0..$lanes->{numlanes}-1;
    }
    
  if(defined $t->{$tag.':backward'}) {  
    for(my $i=0; $i<$lanes->{bck}; $i++) {
      $out[$i] = $t->{$tag.':backward'};
      }
    }

  if(defined $t->{$tag.':both_ways'}) {  
    for(my $i=0; $i<$lanes->{both}; $i++) {
      $out[$i+$lanes->{bck}] = $t->{$tag.':both_ways'};
      }
    }

  if(defined $t->{$tag.':forward'}) {  
    for(my $i=0; $i<$lanes->{fwd}; $i++) {
      $out[$i+$lanes->{bck}+$lanes->{both}+$lanes->{none}] = $t->{$tag.':forward'};
      }
    }
    
  if(defined $t->{$tag.':lanes'}) {
    my @tmp = split('\|',$t->{$tag.':lanes'},-1);
    for(my $i=0; $i<scalar @tmp;$i++) {
      if(defined $tmp[$i] && $tmp[$i] ne "" && !($tmp[$i] =~ /^\s*$/)) {
        $out[$i] = $tmp[$i];
        }
      }
    }

  if(defined $t->{$tag.':lanes:backward'}) {
    my @tmp = split('\|',$t->{$tag.':lanes:backward'},-1);
    for(my $i=0; $i<scalar @tmp;$i++) {
      if(defined $tmp[$i] && $tmp[$i] ne "" && !($tmp[$i] =~ /^\s*$/)) {
        $out[$lanes->{bck}-1-$i] = $tmp[$i];
        }
      }
    }    

  if(defined $t->{$tag.':lanes:both_ways'}) {
    my @tmp = split('\|',$t->{$tag.':lanes:both_ways'},-1);
    for(my $i=0; $i<scalar @tmp;$i++) {
      if(defined $tmp[$i] && $tmp[$i] ne "" && !($tmp[$i] =~ /^\s*$/)) {
        $out[$lanes->{bck}+$i] = $tmp[$i];
        }
      }
    }    

  if(defined $t->{$tag.':lanes:forward'}) {
    my @tmp = split('\|',$t->{$tag.':lanes:forward'},-1);
    for(my $i=0; $i<scalar @tmp;$i++) {
      if(defined $tmp[$i] && $tmp[$i] ne "" && !($tmp[$i] =~ /^\s*$/)) {
        $out[$lanes->{bck}+$lanes->{both}+$lanes->{none}+$i] = $tmp[$i];
        }
      }
    }        
 
  if(!($options =~ /noreverse/) && $obj->{reversed}) {
    @out  = reverse @out;
    }  
  return \@out;
  }

#################################################
## Get or calculate width
#################################################    
sub getWidth {
  my $obj = $_[0];
  $obj->{lanes}{width} = getLaneTags($obj,'width','nonolanes');
  
  if($obj->{lanes}{none}) {
    my $pos = $obj->{lanes}{bck}+$obj->{lanes}{both};
       $pos = $obj->{lanes}{fwd}+$obj->{lanes}{both} if $obj->{reversed};
    $obj->{lanes}{width}[$pos] = 4*0.6;
    if (defined $obj->{tags}{'traffic_calming:width'}) {
      $obj->{lanes}{width}[$pos] = $obj->{tags}{'traffic_calming:width'} ;
      }
    }
  
  if(defined $obj->{tags}{'width'}) {
    $obj->{lanes}{haswidth} = 1;
    my $lw = $obj->{tags}{'width'}/($obj->{lanes}{numlanes});
    for my $i (0..$obj->{lanes}{numlanes}-1) {
      next if ($obj->{lanes}{width}[$i]);
      $obj->{lanes}{width}[$i] = $lw;
      }
    }
  for my $i (0..$obj->{lanes}{numlanes}-1) {
    if ($obj->{lanes}{width}[$i]) {
      $obj->{lanes}{haswidth} = 1;
      $obj->{lanes}{totalwidth} += $obj->{lanes}{width}[$i];
      }
    else {
      $obj->{lanes}{totalwidth} += 4;
      }
    }
  }    
  
#################################################
## Read change:lanes and overtaking for proper lane markings
#################################################   
sub getChange {
  my $obj = shift @_;
  $obj->{lanes}{change} = getLaneTags($obj,'change','noreverse');
  for(my $c=0;$c < scalar (@{$obj->{lanes}{change}}); $c++) {
    $obj->{lanes}{change}[$c] =~ s/yes//;
    $obj->{lanes}{change}[$c] =~ s/only_left/not_right/;
    $obj->{lanes}{change}[$c] =~ s/only_right/not_left/;
    }
  if(defined $obj->{tags}{'overtaking'} && $obj->{tags}{'overtaking'} eq 'no') {
    $obj->{lanes}{change}[$obj->{lanes}{bck}-1]          .=" not_left"  if $obj->{lanes}{bck} != 0;
    $obj->{lanes}{change}[$obj->{lanes}{bck}+$obj->{lanes}{both}]  .=" not_left"  if $obj->{lanes}{fwd} != 0;
    }
#   print Dumper $obj->{lanes}{list};
  ## Put markers on both sides of the street
  $obj->{lanes}{change}[0]  .=" not_right" if $obj->{lanes}{bck};
  $obj->{lanes}{change}[0]  .=" not_left" unless $obj->{lanes}{bck};
  $obj->{lanes}{change}[-1] .=" not_right" if $obj->{lanes}{fwd};
  $obj->{lanes}{change}[-1] .=" not_left" unless $obj->{lanes}{fwd};
  
  if($obj->{reversed}) {
    my @tmp = reverse @{$obj->{lanes}{change}};
    $obj->{lanes}{change} = \@tmp;
    }
  }

#################################################
## Count offset given by placement
#################################################   
sub PlacementCountLanes {
  my $pm = ($_[1]||$_[2]||$_[3]);
  my $obj = $_[0];
  my @p; my $d; my $offset;
  if(defined $pm) {
    @p = split(':',$pm);
    
    if($p[0] eq "right_of")  {$p[1] += 1;}
    if($p[0] eq "middle_of") {$p[1] += .5;}
    if($p[0] eq "transition"){$p[1] = undef;} 
    
    if   (defined $_[2]) {  $d = $obj->{lanes}{bck} + ($p[1]-1);}
    elsif(defined $_[3]) {  $d = $obj->{lanes}{bck} - ($p[1]-1);}
    else                 {  $d = $p[1]-1; }
          
    }
      
    if(defined $d && defined $p[1]) {  
      if($obj->{reversed} == 0) { $offset = $maxlanes - $d;}
      else                      { $offset = $maxlanes - (scalar @{$obj->{lanes}{list}}) + $d;}
      } 
    else                        { $offset = $maxlanes - ($obj->{lanes}{fwd} + $obj->{lanes}{bck} + $obj->{lanes}{both})/2;}
    
  return $offset;
  }


#################################################
## Placement with :start and :end
#################################################   
sub PlacementStartEnd {
  my ($obj) = @_;
  my $offset; my $offend; my $tilt;
  my $start = $obj->{tags}{'placement:start'};
  
  if($obj->{reversed} == 0) { $offset = PlacementCountLanes($obj,$obj->{tags}{'placement:end'} || $obj->{tags}{'placement'},
                                                                 $obj->{tags}{'placement:forward:end'} || $obj->{tags}{'placement:forward'},
                                                                 $obj->{tags}{'placement:backward:end'} || $obj->{tags}{'placement:backward'});}
  else                      { $offset = PlacementCountLanes($obj,$obj->{tags}{'placement:start'} || $obj->{tags}{'placement'},
                                                                 $obj->{tags}{'placement:forward:start'} || $obj->{tags}{'placement:forward'},
                                                                 $obj->{tags}{'placement:backward:start'} || $obj->{tags}{'placement:backward'});} 
  
  if($obj->{reversed} == 0) { $offend = PlacementCountLanes($obj,$obj->{tags}{'placement:start'} || $obj->{tags}{'placement'},
                                                                 $obj->{tags}{'placement:forward:start'} || $obj->{tags}{'placement:forward'},
                                                                 $obj->{tags}{'placement:backward:start'} || $obj->{tags}{'placement:backward'});}
  else                      { $offend = PlacementCountLanes($obj,$obj->{tags}{'placement:end'} || $obj->{tags}{'placement'},
                                                                 $obj->{tags}{'placement:forward:end'} || $obj->{tags}{'placement:forward'},
                                                                 $obj->{tags}{'placement:backward:end'} || $obj->{tags}{'placement:backward'});} 
  $obj->{lanes}{offend} = $offend;
  $obj->{lanes}{offset} = ($offset + $offend) /2;
  
  my $tilt = $offset - $offend;
     $tilt = rad2deg(atan2($tilt*$LANEWIDTH,$LANEHEIGHT));
  $obj->{lanes}{tilt} = -$tilt;  

  return $obj->{lanes}{offset};
  }

  
#################################################
## Read placement tag and calculate drawing offset
#################################################   
sub getPlacement {
  my $obj = shift @_;
  my $t = $obj->{tags};
  my $offset;

  if($lanewidth && $obj->{lanes}{haswidth}) {
    $offset = 0;
    if(defined $t->{'placement'}) {
      if(defined $t->{'oneway'} && $t->{'oneway'} eq "yes") {
        my @p = split(':',$t->{'placement'});
        for(my $i = 0; $i < $p[1];$i++) {
          if($i == $p[1]-1) {
            if($p[0] eq "right_of")  {$offset += $obj->{lanes}{width}[$i]-12/$LANEWIDTH;}
            if($p[0] eq "middle_of") {$offset += $obj->{lanes}{width}[$i]/2-12/$LANEWIDTH;}
            }
          else {
            $offset += $obj->{lanes}{width}[$i]-12/$LANEWIDTH;
            }
          }
        }
      }
    else {
      $offset = $obj->{lanes}{totalwidth}/2;
      }
    $offset  = $maxlanes*4 - $offset;  
    $offset *= $LANEWIDTH/4;  
    }
    
  elsif($USEplacement) {
    if(defined $t->{'placement:start'} || defined $t->{'placement:end'}) {
      $offset = PlacementStartEnd($obj);
      }
    else {  
      $offset = PlacementCountLanes($obj,$t->{'placement'},$t->{'placement:forward'},$t->{'placement:backward'});
      }
    $offset *= $LANEWIDTH;
    }
    
  else {
    $offset = $maxlanes - $obj->{lanes}{bck} - $obj->{lanes}{both}/2.;
    if($obj->{reversed}) {$offset = $maxlanes - $obj->{lanes}{fwd} - $obj->{lanes}{both}/2.;}    
    $offset *= $LANEWIDTH;
    }
  $obj->{lanes}{offset} = $offset;  
  }

  
#################################################
## Check access tags to determine colour of lane
#################################################     
sub makeAccess {
  my $obj = shift @_;
  for(my $i = 0; $i < $obj->{lanes}{numlanes};$i++) {
    if (  $obj->{lanes}{bicycle}[$i] eq 'designated'
       || $obj->{lanes}{bicycle}[$i] eq 'official'
       || $obj->{lanes}{foot}[$i] eq 'designated'
       || $obj->{lanes}{foot}[$i] eq 'official'
       || $obj->{lanes}{psv}[$i] eq 'designated'
       || $obj->{lanes}{bus}[$i] eq 'designated'
       || (($obj->{lanes}{access}[$i] eq 'no' || $obj->{lanes}{vehicle}[$i] eq 'no')) ) {  #$obj->{lanes}{psv}[$i] eq 'yes'  &&
      $obj->{lanes}{access}[$i] .= " restrictlane"; 
      }
    }
  }
  
#################################################
## Run all subs for lane tags
#################################################    
sub InspectLanes {
  my $obj = shift @_;

  OSMLanes::getLanes($obj);
  OSMLanes::getWidth($obj);
  OSMLanes::getPlacement($obj);
  OSMLanes::getChange($obj);
  
  $obj->{lanes}{turn} = getLaneTags($obj,'turn');
  $obj->{lanes}{destinationref}     = getLaneTags($obj,'destination:ref');
  $obj->{lanes}{destination}        = getLaneTags($obj,'destination');
  $obj->{lanes}{maxspeed}           = getLaneTags($obj,'maxspeed','nonolanes');
  $obj->{lanes}{bicycle}            = getLaneTags($obj,'bicycle','nonolanes');
  $obj->{lanes}{bus}                = getLaneTags($obj,'bus'); #,'nonolanes'
  $obj->{lanes}{psv}                = getLaneTags($obj,'psv'); #,'nonolanes'
  $obj->{lanes}{foot}               = getLaneTags($obj,'foot','nonolanes');
  $obj->{lanes}{destinationcolour}  = getLaneTags($obj,'destination:colour');
  $obj->{lanes}{destinationsymbol}  = getLaneTags($obj,'destination:symbol');
  $obj->{lanes}{destinationcountry} = getLaneTags($obj,'destination:country');
  $obj->{lanes}{destinationrefto}   = getLaneTags($obj,'destination:ref:to');
  $obj->{lanes}{destinationto}      = getLaneTags($obj,'destination:to');
  $obj->{lanes}{destinationsymbolto}= getLaneTags($obj,'destination:symbol:to');
  
  $obj->{lanes}{destinationarrow}   = getLaneTags($obj,'destination:arrow');
  $obj->{lanes}{destinationarrowto} = getLaneTags($obj,'destination:arrow:to');
  
  $obj->{lanes}{access}             = getLaneTags($obj,'access');#,'nonolanes'
  $obj->{lanes}{hgv}                = getLaneTags($obj,'hgv','nonolanes');
  makeAccess($obj);
  }
 
1;