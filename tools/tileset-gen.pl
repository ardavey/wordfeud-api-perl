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
  printf( "'%s' => %i,", $letter, $tileset{$letter}->{points} );
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
A	12	1	M	5	1
B	3	4	N	3	3
C	3	2	O	9	1
Ç	2	3	P	3	2
D	4	2	Q	1	8
E	10	1	R	5	1
F	2	5	S	7	2
G	2	4	T	4	2
H	2	4	U	6	2
I	9	1	V	2	4
J	2	6	X	1	10
L	4	2	Z	1	10
