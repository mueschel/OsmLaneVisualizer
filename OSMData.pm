package OSMData;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
use JSON;
use Math::Trig;
use LWP::UserAgent;
use Data::Dumper;
use Exporter;
use Encode qw(encode from_to);
use URI::Escape qw(uri_unescape uri_escape);
our @ISA = 'Exporter';
our @EXPORT = qw($waydata $nodedata $reladata $store $endnodes);

#a hash of way, node and rel. Each is an array to hold different sets of data, each containing an hash of ids.
our $store; 

our $waydata = $store->{way}[0];
our $nodedata = $store->{node}[0];
our $reladata = $store->{rel}[0];
our $endnodes;

#################################################
## Read and organize data
## reads data from JSON input and stores nodes ways and relations in hashes
################################################# 
sub readData {
  my $query = shift @_;
  my $url = 'http://overpass-api.de/api/interpreter';
  my $st = shift @_ || 0;
  my $json;
  
  if($query =~ /elements/) {
    from_to ($query,"iso-8859-1","utf-8");
    $json = uri_unescape($query);
    }
  else {
    my $ua      = LWP::UserAgent->new();
    my $request = $ua->post( $url, ['data' => encode('utf-8',$query)] ); 
      $json = $request->content();
    }
  
  my $data = decode_json($json);

  if(!defined $data->{elements} || scalar @{$data->{elements}} == 0) {
    return -1;
    }
  foreach my $w (@{$data->{elements}}) {
    if ($w->{'type'} eq 'way'  && defined $w->{'tags'}{'highway'} && $w->{'tags'}{'highway'} ne 'platform') {  
      $store->{way}[$st]{$w->{'id'}}{tags} = $w->{'tags'};
      $store->{way}[$st]{$w->{'id'}}{nodes} = $w->{'nodes'};
      $store->{way}[$st]{$w->{'id'}}{id} = $w->{'id'};
      }
    elsif ($w->{'type'} eq 'node') {  
      $store->{node}[$st]{$w->{'id'}}{tags} = $w->{'tags'};
      $store->{node}[$st]{$w->{'id'}}{lat} = $w->{'lat'};
      $store->{node}[$st]{$w->{'id'}}{lon} = $w->{'lon'};
      $store->{node}[$st]{$w->{'id'}}{id} = $w->{'id'};
      }
    elsif ($w->{'type'} eq 'relation') {  
      $store->{rel}[$st]{$w->{'id'}} = $w;
      $store->{rel}[$st]{$w->{'id'}}{id} = $w->{'id'};
      }
    }
  if(scalar $store->{way}[$st] < 2) {
    return -2;
    }
  foreach my $w (keys $store->{way}[$st]) {
    next unless defined $store->{way}[$st]{$w}{tags}{'highway'};
    push(@{$endnodes->[$st]{$store->{way}[$st]{$w}{nodes}[0]}},$w);
    push(@{$endnodes->[$st]{$store->{way}[$st]{$w}{nodes}[-1]}},$w);
    }    

  
  $waydata = $store->{way}[0];
  $nodedata = $store->{node}[0];
  $reladata = $store->{rel}[0];
  return 0;
  }

#################################################
## Collect information about order of ways
## for each way, store last and next way as well as begin and end node
################################################# 
sub organizeWays {
  my @tmpw = sort keys %{$waydata};
  foreach my $id (@tmpw) {
    $waydata->{$id}->{begin} = $waydata->{$id}{'nodes'}[0];
    $waydata->{$id}->{end}   = $waydata->{$id}{'nodes'}[-1];
    foreach my $x (@{$endnodes->[0]{$waydata->{$id}->{begin}}}) {
      next if $x == $id;
      if ($waydata->{$id}->{begin} == $waydata->{$x}->{'nodes'}[0]) {
        push(@{$waydata->{$id}->{before}},$x);
        }
      if ($waydata->{$id}->{begin} == $waydata->{$x}->{'nodes'}[-1]) {
        push(@{$waydata->{$id}->{before}},$x);
        }
      }  
    foreach my $x (@{$endnodes->[0]{$waydata->{$id}->{end}}}) {
      next if $x == $id;
      if ($waydata->{$id}->{end} == $waydata->{$x}->{'nodes'}[0]) {
        push(@{$waydata->{$id}->{after}},$x);
        }
      if ($waydata->{$id}->{end} == $waydata->{$x}->{'nodes'}[-1]) {
        push(@{$waydata->{$id}->{after}},$x);
        }
      }
    }
  }  
  
  
#################################################
## Lists all tags of a way (expects node objects, not ids!)
#################################################
sub listtags {
  my $id = shift @_;
  my $rev = shift @_;
  my $t = $id->{tags};
  my $ret = "";
  foreach my $k (sort keys $t) {
    $ret .= $k." = ".$t->{$k}."\n";
    }
  return $ret;  
  }
  
#################################################
## Distance between two nodes
#################################################
sub calcDistance {
  my ($a,$b) = @_;
  my $lat = ($nodedata->{$a}{lat} + $nodedata->{$b}{lat}) / 2 * 0.01745;
  my $dx = 111.3 * cos($lat) * ($nodedata->{$a}{lon} - $nodedata->{$b}{lon});
  my $dy = 111.3 * ($nodedata->{$a}{lat} - $nodedata->{$b}{lat});
  return sqrt($dx * $dx + $dy * $dy)*1000;
  } 

  
#################################################
## Direction of X-A (expects node objects, not ids!)
#################################################
sub calcDirection {
  my ($x,$a) = @_;
  my $lat = $x->{lat} * 0.01745;
  my $dxa = 111.3 * cos($lat) * ($a->{lon} - $x->{lon});
  my $dya = 111.3 * ($a->{lat} - $x->{lat});
  
  return 0 if($dxa == 0);
  my $anga = rad2deg(atan(abs($dya)/abs($dxa)));
  $anga = -$anga     if $dxa>=0 && $dya>=0;
  $anga = -180+$anga if $dxa<0 && $dya>=0;
  $anga = 180-$anga  if $dxa<0 && $dya<0;
  $anga = 0+$anga    if $dxa>=0 && $dya<0;
  
  return $anga;
  }     
  
  
#################################################
## Length of a way
#################################################  
sub calcLength {
  my $w = shift @_;
  my $l = 0;
  return unless defined $waydata->{$w}{nodes};
  for(my $i=1; $i < scalar @{$waydata->{$w}{nodes}}; $i++) {
    $l += calcDistance($waydata->{$w}{nodes}[$i-1],$waydata->{$w}{nodes}[$i]);
    }
  return $l;
  }
  
#################################################
## 
#################################################  
sub NormalizeAngle { 
  my $a = shift @_;
  while($a<-180) {$a+=360;}
  while($a>180) {$a-=360;}
  return $a;
  }

#################################################
## Majority voting - http://www.perlmonks.org/?node_id=235679  
################################################# 
sub MostFrequent {
  my @items = @_;
  my %count;
  $count{$_}++ for @items;
  my ($winner, $winner_count) = each %count;
  while (my ($maybe, $maybe_count) = each %count) {
    if ($maybe_count > $winner_count) {
      $winner = $maybe;
      $winner_count = $maybe_count;
      }
    }
  return $winner;
  }
  
1;