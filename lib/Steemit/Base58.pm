package Steemit::Base58;
use Modern::Perl;

=head1 NAME

Steemit::Base58 - perl lirary for base58 encoding the bitcoin way

=head1 SYNOPSIS

    use Steemit::Base58

    my $binary = Steemit::Base58::decode_base58( $base58_string )
    my $base58 = Steemit::Base58::encode_base58( $binary )

=cut

use Math::BigInt try => 'GMP,Pari';
use Carp;

# except 0 O D / 1 l I
my $chars = [qw(
    1 2 3 4 5 6 7 8 9

	A B C D E F G H J
    K L M N P Q R S T
	U V W X Y Z

    a b c d e f g h i
    j k m n o p q r s
    t u v w x y z

)];
my $test = qr/^[@{[ join "", @$chars ]}]+$/;

my $map = do {
    my $i = 0;
    +{ map { $_ => $i++ } @$chars };
};

sub encode_base58 {
    my ($binary) = @_;
    return $chars->[0] unless $binary;

    my $bigint = Math::BigInt->from_bytes($binary);
say $bigint."";
    my $base58 = '';
    my $base = @$chars;

    while ($bigint->is_pos) {
        my ($quotient, $rest ) = $bigint->bdiv($base);
        $base58 = $chars->[$rest] . $base58;
    }

    return $base58;
}

sub decode_base58 {
    my $base58 = shift;
    $base58 =~ tr/0OlI/DD11/;
    $base58 =~ $test or croak "Invalid Base58";

    my $decoded = Math::BigInt->new(0);
    my $multi   = Math::BigInt->new(1);
    my $base    = @$chars;

    while (length $base58 > 0) {
        my $digit = chop $base58;
        $decoded->badd($multi->copy->bmul($map->{$digit}));
        $multi->bmul($base);
    }

    return $decoded->to_bytes;
}


1;
