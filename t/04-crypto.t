#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Math::EllipticCurve::Prime;

plan tests => 4;

use_ok( 'Steemit::Crypto' ) || print "Bail out!\n";

my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');

my $g = $curve->g;

my( $i ) = Steemit::Crypto::get_recovery_factor( $g->x, $g->y );

diag "i =".$i;
diag "y = ".$g->y;

my $is_odd = Steemit::Crypto::recover_y( $g->x, $i );

is( $g->y, $is_odd, "getting y from x with isOdd seems to work");

my $message = "hello world";
my $key    = Math::BigInt->new(2);
my $pubkey = $g->add( $g );
my ( $r, $s,$i ) = Steemit::Crypto::ecdsa_sign( $message, $key );
diag "r: ".$r;
diag "s: ".$s;

my $recovered_pubkey = Steemit::Crypto::recoverPubKey($message,$r,$s,$i);

ok( Steemit::Crypto::ecdsa_verify( $message, $pubkey, $r, $s ), "signing seems to work with trivial key" );
ok( Steemit::Crypto::ecdsa_verify( $message, $recovered_pubkey, $r, $s ), "signing seems to work with recovered key" );

diag $i;



