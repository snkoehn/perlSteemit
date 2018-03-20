#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

use_ok( 'Steemit::WsClient' ) || print "Bail out!\n";

diag( "Testing Steemit $Steemit::WsClient::VERSION, Perl $], $^X" );

my $steem = Steemit::WsClient->new;

isa_ok( $steem, 'Steemit::WsClient', 'constructor will return a Steemit object');

my $steem_time = '2018-02-24T16:17:09';

my $epoch      = $steem->steem_time_to_epoch( $steem_time );

my $timeplus10 = $steem->delta_steem_time( $steem_time, 600 );

is( $timeplus10, '2018-02-24T16:27:09', 'delta time seems to work');

my $timeminus10 = $steem->delta_steem_time( $steem_time, -600 );

is( $timeminus10, '2018-02-24T16:07:09', 'delta time seems to work');

is( $steem->steem_time_to_epoch( $timeminus10), ($epoch -600), "crosscheck on time conversions"  );


