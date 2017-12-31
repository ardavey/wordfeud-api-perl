#!/usr/bin/perl

use strict;
use warnings;

use 5.010;

my @data = <DATA>;
my $datastring = join( "\t", @data );
$datastring =~ s/\n//g;

@data = split( /\t/, $datastring );
my %tileset = ( '?' => { count => 2, points => 0 } );

while ( my ( $letter, $count, $points ) = splice( @data, 0, 3 ) ) {
  $tileset{$letter} = { count => $count, points => $points };
}

# tile count hash
my $counter = 1;
foreach my $letter ( sort keys %tileset ) {
  printf( "'%s' => %i,", $letter, $tileset{$letter}->{count} );
  if ( $counter++ % 2 == 0 ) {
    print "\n";
  }
  else {
    print " ";
  }
}

# tile distro list
my @letters = ();
foreach my $letter ( sort keys %tileset ) {
  foreach ( 1..$tileset{$letter}->{count} ) {
    push @letters, $letter;
  }
}

print "\n\n";

print 'qw( ';
$counter = 1 ;
foreach my $letter ( @letters ) {
  print $letter;
  if ( $counter++ % 30 == 0 ) {
    print "\n";
  }
  else {
    print " ";
  }  
}
print ')';


# Paste the raw tabular data from https://wordfeud.com/wf/help/ into this section, minus the column headers.
__DATA__
A	11	1	M	3	3
B	1	8	N	9	1
C	1	10	O	5	2
D	1	6	P	2	4
E	9	1	R	2	4
F	1	8	S	7	1
G	1	8	T	9	1
H	2	4	U	4	3
I	10	1	V	2	4
J	2	4	Y	2	4
K	6	3	Ä	5	2
L	6	2	Ö	1	7
