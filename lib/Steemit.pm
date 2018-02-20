package Steemit;

use Modern::Perl '2017';
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);

has url     => 'https://steemd.steemitstage.com';
has ua      =>  sub { Mojo::UserAgent->new };


sub _request {
   my( $self, $api, $method, @params ) = @_;
   my $response = $self->ua->get( $self->url, json => {
      jsonrpc => '2.0',
      method  => 'call',
      params  => [$api,$method,[@params]],
      id      => int rand 100,
   })->result;

   die "error while requesting steemd ". $response->to_string unless $response->is_success;

   my $result   = decode_json $response->body;

   return $result->{result} if $result->{result};
   if( my $error = $result->{error} ){
      die $error->{message};
   }
   #ok no error no result
   require Data::Dumper;
   die "unexpected api result: ".Data::Dumper::Dumper( $result );
}

sub get_accounts {
   my( $self, @params ) = @_;
   return $self->_request('database_api','get_accounts',@params);
}

1;