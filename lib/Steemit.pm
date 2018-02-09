package Steemit;

use Modern::Perl '2017';
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);

has url     => 'steemd.minnowsupportproject.org';
has ua      =>  sub { Mojo::UserAgent->new };


1;