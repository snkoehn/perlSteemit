#!/usr/bin/env perl
use Modern::Perl '2017';
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok('Steemit');

my $steem = Steemit->new;

isa_ok( $steem, 'Steemit', 'constructor will return a Steemit object');


done_testing;

