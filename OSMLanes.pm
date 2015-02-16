package OSMLanes;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';
use Data::Dumper;
use OSMData;


use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw($lanes $maxlanes $placement $adjacent $lanewidth $extrasize $LANEWIDTH);

our $LANEWIDTH = 120;
our $lanes;
our $placement = 0;
our $maxlanes = 4;
our $adjacent = 0;
our $lanewidth = 0;
our $extrasize = 0;

#################################################
## Read and interpret number of lanes
#################################################  
sub getLanes {
  my $obj = shift @_;
  my $t = $obj->{tags};
  my @lanedir;
  my $fwdlane = 0; my $bcklane = 0; my $nolane = 0; my $bothlane = 0;

  if(defined $t->{'lanes:forward'} && defined $t->{'lanes:backward'}){
    $fwdlane = $t->{'lanes:forward'};
    $bcklane = $t->{'lanes:backward'};
    if(defined $t->{'lanes'} && $t->{'lanes'} > $fwdlane + $bcklane) {
      $bothlane = $t->{'lanes'} - $fwdlane - $bcklane;
      }
    }
  elsif(defined $t->{'lanes:forward'} && defined $t->{'lanes'}){
    $fwdlane = $t->{'lanes:forward'};
    $bcklane = $t->{'lanes'}-$fwdlane;
    }
  elsif(defined $t->{'lanes:backward'} && defined $t->{'lanes'}){
    $bcklane = $t->{'lanes:backward'};
    $fwdlane = $t->{'lanes'}-$bcklane;
    }
  elsif(defined $t->{'lanes'}) {
    if(defined $t->{'oneway'} && $t->{'oneway'} ne "no") {
      $fwdlane = $t->{'lanes'};
      }
    else{
      $fwdlane = $t->{'lanes'}/2;
      $bcklane = $t->{'lanes'}/2;
      }
    }
  elsif(defined $t->{'oneway'} && $t->{'oneway'} ne "no") {
    $fwdlane = 1;
    }
  else {
    $fwdlane = 1;
    $bcklane = 1;
    }
  if(!$obj->{reversed}) {
    for(my $i=0; $i<$bcklane;$i++)  {push(@lanedir,'backward');}
    for(my $i=0; $i<$bothlane;$i++) {push(@lanedir,'nolane');}
    for(my $i=0; $i<$fwdlane;$i++)  {push(@lanedir,'forward');}
    }
  else {
    for(my $i=0; $i<$fwdlane;$i++)  {push(@lanedir,'backward');}
    for(my $i=0; $i<$bothlane;$i++) {push(@lanedir,'nolane');}
    for(my $i=0; $i<$bcklane;$i++)  {push(@lanedir,'forward');}
    }
    
  $obj->{lanes}{fwd}  = $fwdlane;
  $obj->{lanes}{bck}  = $bcklane;
  $obj->{lanes}{both} = $bothlane;
  $obj->{lanes}{none} = $nolane;
  $obj->{lanes}{list} = \@lanedir;
  $obj->{lanes}{numlanes} = scalar (@{$obj->{lanes}{list}});

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
  
  if(defined $t->{$tag} && !($options =~ /nonolanes/))   {
    for(my $i=0; $i<$lanes->{bck};$i++)  {push(@out,$t->{$tag});}
    for(my $i=0; $i<$lanes->{both};$i++) {push(@out,'');}
    for(my $i=0; $i<$lanes->{fwd};$i++)  {push(@out,$t->{$tag});}
    }
  elsif(defined $t->{$tag.':lanes'}) {
    my @tmp = split('\|',$t->{$tag.':lanes'},-1);
    push(@out,@tmp);
    }
  else{  
    if(defined $t->{$tag.':lanes:backward'}) {
      my @tmp = split('\|',$t->{$tag.':lanes:backward'},-1);
      push(@out,reverse @tmp);
      }  
    elsif ($lanes->{bck}) {
      for(my $i=0; $i<$lanes->{bck};$i++){push(@out,'');}
      }
    
    for(my $i=0; $i<$lanes->{both};$i++){push(@out,'');}
    
    if(defined $t->{$tag.':lanes:forward'}) {
      my @tmp = split('\|',$t->{$tag.':lanes:forward'},-1);
      push(@out,@tmp);
      }
    else {
      for(my $i=0; $i<$lanes->{fwd};$i++){push(@out,'');}
      }
    }
    
  if(!($options =~ /noreverse/) && $obj->{reversed}) {
    @out  = reverse @out;
    }  
  return \@out;
  }


  
  
sub getTurn {
  $_[0]->{lanes}{turn} = getLaneTags($_[0],'turn');
  }

sub getDestination {  
  $_[0]->{lanes}{destination} = getLaneTags($_[0],'destination');
  } 
  
sub getDestinationRef {  
  $_[0]->{lanes}{destinationref} = getLaneTags($_[0],'destination:ref');
  }  

sub getDestinationColour {  
  $_[0]->{lanes}{destinationcolour} = getLaneTags($_[0],'destination:colour');
  }  
  
sub getDestinationSymbol {  
  $_[0]->{lanes}{destinationsymbol} = getLaneTags($_[0],'destination:symbol');
  } 
  
sub getDestinationCountry {  
  $_[0]->{lanes}{destinationcountry} = getLaneTags($_[0],'destination:country');
  }
  
sub getMaxspeed {
  $_[0]->{lanes}{maxspeed} = getLaneTags($_[0],'maxspeed','nonolanes');
  }  

sub getWidth {
  my $obj = $_[0];
  $obj->{lanes}{width} = getLaneTags($obj,'width','nonolanes');
  if(defined $obj->{tags}{'width'}) {
    $obj->{lanes}{haswidth} = 1;
    my $lw = $obj->{tags}{'width'}/$obj->{lanes}{numlanes};
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
    }
  if(defined $obj->{tags}{'overtaking'} && $obj->{tags}{'overtaking'} eq 'no') {
    $obj->{lanes}{change}[$obj->{lanes}{bck}-1]          .=" not_left"  if $obj->{lanes}{bck} != 0;
    $obj->{lanes}{change}[$obj->{lanes}{bck}+$obj->{lanes}{both}]  .=" not_left"  if $obj->{lanes}{fwd} != 0;
    }

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
            if($p[0] eq "right_of")  {$offset += $obj->{lanes}{width}[$i];}
            if($p[0] eq "middle_of") {$offset += $obj->{lanes}{width}[$i]/2;}
            }
          else {
            $offset += $obj->{lanes}{width}[$i];
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
  else {
    if($placement) {
      $offset = $maxlanes - (scalar @{$obj->{lanes}{list}})/2;
      my $d;
      if(defined $t->{'placement'} && defined $t->{'oneway'} && $t->{'oneway'} eq "yes") {
        my @p = split(':',$t->{'placement'});
        $d = $p[1]-1;
        if($p[0] eq "right_of")  {$d += 1;}
        if($p[0] eq "middle_of") {$d += .5;}
        if($p[0] eq "transition"){$d = undef;}
        }
      elsif(defined $t->{'placement:forward'}) {
        my @p = split(':',$t->{'placement:forward'});
        $d = $p[1]-1 + $obj->{lanes}{bck};
        if($p[0] eq "right_of")  {$d += 1;}
        if($p[0] eq "middle_of") {$d += .5;}
        }
      elsif(defined $t->{'placement:backward'}) {
        my @p = split(':',$t->{'placement:backward'});
        $d = $p[1]-1;
        if($p[0] eq "right_of")  {$d += 1;}
        if($p[0] eq "middle_of") {$d += .5;}
        $d = $obj->{lanes}{bck} - $d;
        }
      if(defined $d) {  
        if($obj->{reversed} == 0) {
          $offset = $maxlanes - $d;
          }
        else {
          $offset = $maxlanes  - (scalar @{$obj->{lanes}{list}}) + $d;
          }
        }  
      $offset *= $LANEWIDTH;  
      }
    else {
      $offset = $maxlanes - $obj->{lanes}{bck} - $obj->{lanes}{both}/2.;
      if($obj->{reversed}) {$offset = $maxlanes - $obj->{lanes}{fwd} - $obj->{lanes}{both}/2.;}    
      $offset *= $LANEWIDTH;
      }
    }
  $obj->{lanes}{offset} = $offset;  
  }

  
sub InspectLanes {
  my $obj = shift @_;

  OSMLanes::getLanes($obj);
  OSMLanes::getTurn($obj);
  OSMLanes::getWidth($obj);
  OSMLanes::getPlacement($obj);
  OSMLanes::getChange($obj);
  OSMLanes::getDestinationRef($obj);
  OSMLanes::getDestination($obj);
  OSMLanes::getMaxspeed($obj);
  OSMLanes::getDestinationColour($obj);
  OSMLanes::getDestinationSymbol($obj);
  OSMLanes::getDestinationCountry($obj);

  }
  
  
1;