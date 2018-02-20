#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok( 'Steemit' ) || print "Bail out!\n";

diag( "Testing Steemit $Steemit::VERSION, Perl $], $^X" );

my $steem = Steemit->new;

isa_ok( $steem, 'Steemit', 'constructor will return a Steemit object');


