#/usr/bin/env perl
use Modern::Perl;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Steemit;

my $steem = Steemit->new;

say "Initialized Steemit client with url ".$steem->url;


use Data::Dumper;

say Dumper( $steem->get_accounts(['utopian-io']));
