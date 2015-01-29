package OSMLanes;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';

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

sub resetLanes {
  $lanes = undef;
  }

#################################################
## Read and interpret number of lanes
#################################################  
sub getLanes {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
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
  if(!$waydata->{$id}{reversed}) {
    for(my $i=0; $i<$bcklane;$i++)  {push(@lanedir,'backward');}
    for(my $i=0; $i<$bothlane;$i++) {push(@lanedir,'nolane');}
    for(my $i=0; $i<$fwdlane;$i++)  {push(@lanedir,'forward');}
    }
  else {
    for(my $i=0; $i<$fwdlane;$i++)  {push(@lanedir,'backward');}
    for(my $i=0; $i<$bothlane;$i++) {push(@lanedir,'nolane');}
    for(my $i=0; $i<$bcklane;$i++)  {push(@lanedir,'forward');}
    }
    
  $lanes->{fwd}  = $fwdlane;
  $lanes->{bck}  = $bcklane;
  $lanes->{both} = $bothlane;
  $lanes->{none} = $nolane;
  $lanes->{list} = \@lanedir;
  $lanes->{numlanes} = scalar (@{$lanes->{list}});

  }


#################################################
## generic reader for :lanes tagging
#################################################  
sub getLaneTags {
  my $id = shift @_;
  my $tag = shift @_;
  my $options = shift @_;
  my $t = $waydata->{$id}{tags};
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
    
  if(!($options =~ /noreverse/) && $waydata->{$id}{reversed}) {
    @out  = reverse @out;
    }  
  return \@out;
  }


  
  
sub getTurn {
  $lanes->{turn} = getLaneTags($_[0],'turn');
  }

sub getDestination {  
  $lanes->{destination} = getLaneTags($_[0],'destination');
  } 
  
sub getDestinationRef {  
  $lanes->{destinationref} = getLaneTags($_[0],'destination:ref');
  }  

sub getDestinationColour {  
  $lanes->{destinationcolour} = getLaneTags($_[0],'destination:colour');
  }  
  
sub getDestinationSymbol {  
  $lanes->{destinationsymbol} = getLaneTags($_[0],'destination:symbol');
  } 
  
sub getDestinationCountry {  
  $lanes->{destinationcountry} = getLaneTags($_[0],'destination:country');
  }
  
sub getMaxspeed {
  $lanes->{maxspeed} = getLaneTags($_[0],'maxspeed','nonolanes');
  }  

sub getWidth {
  $lanes->{width} = getLaneTags($_[0],'width','nonolanes');
  if(defined $waydata->{$_[0]}{tags}{'width'}) {
    $lanes->{haswidth} = 1;
    my $lw = $waydata->{$_[0]}{tags}{'width'}/$lanes->{numlanes};
    for my $i (0..$lanes->{numlanes}-1) {
      next if ($lanes->{width}[$i]);
      $lanes->{width}[$i] = $lw;
      }
    }
  for my $i (0..$lanes->{numlanes}-1) {
    if ($lanes->{width}[$i]) {
      $lanes->{haswidth} = 1;
      $lanes->{totalwidth} += $lanes->{width}[$i];
      }
    }
  }    
  
#################################################
## Read change:lanes and overtaking for proper lane markings
#################################################   
sub getChange {
  my $id = shift @_;
  $lanes->{change} = getLaneTags($id,'change','noreverse');
  for(my $c=0;$c < scalar (@{$lanes->{change}}); $c++) {
    $lanes->{change}[$c] =~ s/yes//;
    }
  if(defined $waydata->{$id}{tags}{'overtaking'} && $waydata->{$id}{tags}{'overtaking'} eq 'no') {
    $lanes->{change}[$lanes->{bck}-1]          .=" not_left"  if $lanes->{bck} != 0;
    $lanes->{change}[$lanes->{bck}+$lanes->{both}]  .=" not_left"  if $lanes->{fwd} != 0;
    }

  ## Put markers on both sides of the street    
  $lanes->{change}[0]  .=" not_right" if $lanes->{bck};
  $lanes->{change}[0]  .=" not_left" unless $lanes->{bck};
  $lanes->{change}[-1] .=" not_right" if $lanes->{fwd};
  $lanes->{change}[-1] .=" not_left" unless $lanes->{fwd};
  
  if($waydata->{$id}{reversed}) {
    my @tmp = reverse @{$lanes->{change}};
    $lanes->{change} = \@tmp;
    }
  }

  
#################################################
## Read placement tag and calculate drawing offset
#################################################   
sub getPlacement {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
  my $offset;

  if($lanewidth && $lanes->{haswidth}) {
    $offset = 0;
    if(defined $t->{'placement'}) {
      if(defined $t->{'oneway'} && $t->{'oneway'} eq "yes") {
        my @p = split(':',$t->{'placement'});
        for(my $i = 0; $i < $p[1];$i++) {
          if($i == $p[1]-1) {
            if($p[0] eq "right_of")  {$offset += $lanes->{width}[$i];}
            if($p[0] eq "middle_of") {$offset += $lanes->{width}[$i]/2;}
            }
          else {
            $offset += $lanes->{width}[$i];
            }
          }
        }
      }
    else {
      $offset = $lanes->{totalwidth}/2;
      }
    $offset  = $maxlanes*4 - $offset;  
    $offset *= $LANEWIDTH/4;  
    }
  else {
    if($placement) {
      $offset = $maxlanes - (scalar @{$lanes->{list}})/2;
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
        $d = $p[1]-1 + $lanes->{bck};
        if($p[0] eq "right_of")  {$d += 1;}
        if($p[0] eq "middle_of") {$d += .5;}
        }
      elsif(defined $t->{'placement:backward'}) {
        my @p = split(':',$t->{'placement:backward'});
        $d = $p[1]-1;
        if($p[0] eq "right_of")  {$d += 1;}
        if($p[0] eq "middle_of") {$d += .5;}
        $d = $lanes->{bck} - $d;
        }
      if(defined $d) {  
        if($waydata->{$id}{reversed} == 0) {
          $offset = $maxlanes - $d;
          }
        else {
          $offset = $maxlanes  - (scalar @{$lanes->{list}}) + $d;
          }
        }  
      $offset *= $LANEWIDTH;  
      }
    else {
      $offset = $maxlanes - $lanes->{bck} - $lanes->{both}/2.;
      if($waydata->{$id}{reversed}) {$offset = $maxlanes - $lanes->{fwd} - $lanes->{both}/2.;}    
      $offset *= $LANEWIDTH;
      }
    }
  $lanes->{offset} = $offset;  
  }

  
  
  
  
1;