package Steemit::WsClient;

=head1 NAME

Steemit::WsClient - perl library for interacting with the steemit websocket services!

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS


    use Steemit::WsClient;

    my $foo = Steemit::WsClient->new();
    my $steem = Steemit::WsClient->new( url => 'https://some.steemit.d.node.address');

    say "Initialized Steemit::WsClient client with url ".$steem->url;

    #get the last 99 discussions with the tag utopian-io
    #truncate the body since we dont care here
    my $discussions = $steem->get_discussions_by_created({
          tag => 'utopian-io',
          limit => 99,
          truncate_body => 100,
    });

    #extract the author names out of the result
    my @author_names = map { $_->{author} } @$discussions;
    say "last 99 authors: ".join(", ", @author_names);

    #load the author details
    my $authors = $steem->get_accounts( [@author_names] );
    #say Dumper $authors->[0];

    #calculate the reputation average
    my $reputation_sum = 0;
    for my $author ( @$authors ){
       $reputation_sum += int( $author->{reputation} / 1000_000_000 );
    }

    say "Average reputation of the last 99 utopian authors: ". ( int( $reputation_sum / scalar(@$authors) )  / 100 );


=head1 DEPENDENCIES

you will need some packages.
openssl support for https
libgmp-dev for large integer aritmetic needd for the eliptical curve calculations

   libssl-dev zlib1g-dev libgmp-dev


=head1 SUBROUTINES/METHODS

=cut

use Modern::Perl;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;
use Encode;
use Carp;

has url                => 'https://api.steemit.com/';
has ua                 => sub { Mojo::UserAgent->new };
has posting_key        => undef;
has active_key         => undef;
has plain_posting_key  => \&_transform_private_key;
has plain_active_key   => \&_transform_private_key_active;


=head2 all database api methods of the steemit api

L<https://github.com/steemit/steem/blob/master/libraries/app/database_api.cpp>

      get_miner_queue
      lookup_account_names
      get_discussions
      get_discussions_by_blog
      get_witness_schedule
      get_open_orders
      get_trending_tags
      lookup_witness_accounts
      get_discussions_by_children
      get_accounts
      get_savings_withdraw_to
      get_potential_signatures
      get_required_signatures
      get_order_book
      get_key_references
      get_tags_used_by_author
      get_account_bandwidth
      get_replies_by_last_update
      get_dynamic_global_properties
      get_block
      get_witnesses
      get_transaction_hex
      get_comment_discussions_by_payout
      get_discussions_by_votes
      get_witness_by_account
      verify_authority
      get_config
      get_account_votes
      get_discussions_by_promoted
      get_conversion_requests
      get_account_history
      get_escrow
      get_discussions_by_comments
      get_feed_history
      get_hardfork_version
      set_block_applied_callback
      get_discussions_by_author_before_date
      get_discussions_by_hot
      get_discussions_by_payout
      get_discussions_by_trending
      get_recovery_request
      get_reward_fund
      get_chain_properties
      get_witnesses_by_vote
      get_account_references
      get_post_discussions_by_payout
      get_active_witnesses
      get_ops_in_block
      get_discussions_by_created
      get_discussions_by_active
      get_account_count
      get_owner_history
      get_next_scheduled_hardfork
      get_savings_withdraw_from
      get_active_votes
      get_current_median_history_price
      get_transaction
      get_block_header
      get_expiring_vesting_delegations
      get_witness_count
      get_content
      verify_account_authority
      get_liquidity_queue
      get_discussions_by_feed
      get_discussions_by_cashout
      get_content_replies
      lookup_accounts
      get_state
      get_withdraw_routes


=head2 get_discussions_by_xxxxxx

all those methods will sort the results differently and accept one query parameter with the values:

   {
      tag   => 'tagtosearch',   # optional
      limit => 1,               # max 100
      filter_tags => [],        # tags to filter out
      select_authors => [],     # only those authors
      truncate_body  => 0       # the number of bytes of the post body to return, 0 for all
      start_author   => ''      # used together with the start_permlink gor pagination
      start_permlink => ''      #
      parent_author  => ''      #
      parent_permlink => ''     #
   }

so one example on how to get 200 discussions would be


   my $discussions = $steem->get_discussions_by_created({
         limit => 100,
         truncate_body => 1,
   });

   my $discussion = $discussions[-1];

   push @$discussions, $steem->get_discussions_by_created({
         limit => 100,
         truncate_body => 1,
         start_author   => $discussion->{author},
         start_permlink => $discussion->{permlink},
   });

=head2 $steem->get_discussions_by_author_before_date($author,$permlink,$steem_time,$limit);

this method takes in:

    an author for wich to display the discussions
    an optional pemalink of a post of you are only interested in comments below one specific post
    a date before wich the content is displayed ( or not after ;)
    a limit of posts to look for

=cut

sub _request {
   my( $self, $api, $method, @params ) = @_;
   my $response = $self->ua->post( $self->url, json => {
      jsonrpc => '2.0',
      method  => 'call',
      params  => [$api,$method,[@params]],
      id      => int rand 100,
   })->result;

   die "error while requesting steemd ". $response->to_string unless $response->is_success;

   my $result   = eval{ decode_json  Encode::encode('UTF-8',$response->body)} or die $response->to_string.$@;

   return $result->{result} if $result->{result};
   if( my $error = $result->{error} ){
      die $error->{message};
   }
   #ok no error no result
   require Data::Dumper;
   die "unexpected api result: ".Data::Dumper::Dumper( $result );
}

_install_methods();

sub _install_methods {
   my %definition = _get_api_definition();
   for my $api ( keys %definition ){
      for my $method ( @{ $definition{$api} } ){
         no strict 'subs';
         no strict 'refs';
         my $package_sub = join '::', __PACKAGE__, $method;
         *$package_sub = sub {
            shift->_request($api,$method,@_);
         }
      }
   }
}


sub _get_api_definition {

   my @database_api = qw(
      get_miner_queue
      lookup_account_names
      get_discussions
      get_discussions_by_blog
      get_witness_schedule
      get_open_orders
      get_trending_tags
      lookup_witness_accounts
      get_discussions_by_children
      get_accounts
      get_savings_withdraw_to
      get_potential_signatures
      get_required_signatures
      get_order_book
      get_tags_used_by_author
      get_account_bandwidth
      get_replies_by_last_update
      get_dynamic_global_properties
      get_block
      get_witnesses
      get_transaction_hex
      get_comment_discussions_by_payout
      get_discussions_by_votes
      get_witness_by_account
      verify_authority
      get_config
      get_account_votes
      get_discussions_by_promoted
      get_conversion_requests
      get_account_history
      get_escrow
      get_discussions_by_comments
      get_feed_history
      get_hardfork_version
      set_block_applied_callback
      get_discussions_by_author_before_date
      get_discussions_by_hot
      get_discussions_by_payout
      get_discussions_by_trending
      get_recovery_request
      get_reward_fund
      get_chain_properties
      get_witnesses_by_vote
      get_account_references
      get_post_discussions_by_payout
      get_active_witnesses
      get_ops_in_block
      get_discussions_by_created
      get_discussions_by_active
      get_account_count
      get_owner_history
      get_next_scheduled_hardfork
      get_savings_withdraw_from
      get_active_votes
      get_current_median_history_price
      get_transaction
      get_block_header
      get_expiring_vesting_delegations
      get_witness_count
      get_content
      verify_account_authority
      get_liquidity_queue
      get_discussions_by_feed
      get_discussions_by_cashout
      get_content_replies
      lookup_accounts
      get_state
      get_withdraw_routes
   );

   return (
      database_api          => [@database_api],
      account_by_key_api    => [ qw( get_key_references )],
   )
}


=head2 vote

this requires you to initialize the module with your private posting key like this:


   my $steem = Steemit::WsClient->new(
      posting_key => 'copy this one from the steemit site',

   );

   $steem->vote($discussion,$weight)

weight is optional default is 10000 wich equals to 100%


=cut


sub vote {
   my( $self, @discussions ) = @_;

   my $weight;
   $weight = pop @discussions, unless ref $discussions[-1];
   $weight   = $weight // 10000;
   my $voter = $self->get_key_references([$self->public_posting_key])->[0][0];

   my @operations = map { [
         vote => {
            voter    => $voter,
            author   => $_->{author},
            permlink => $_->{permlink},
            weight   => $weight,
         }
      ]
      } @discussions;
   return $self->_broadcast_transaction(@operations);
}

=head2 comment

this requires you to initialize the module with your private posting key like this:


   my $steem = Steemit::WsClient->new(
      posting_key => 'copy this one from the steemit site',

   );

   $steem->comment(
         "parent_author"   => $parent_author,
         "parent_permlink" => $parent_permlink,
         "author"          => $author,
         "permlink"        => $permlink,
         "title"           => $title,
         "body"            => $body,
         "json_metadata"   => $json_metadata,
   )

you need at least a permlink and body
fill the parent parameters to comment on an existing post
json metadata can be already a json string or a perl hash

=cut

sub comment {
   my( $self, %params ) = @_;

   my $parent_author   = $params{parent_author} // '';
   my $parent_permlink = $params{parent_permlink} // '';
   my $permlink        = $params{permlink} or die "permlink missing for comment";
   my $title           = $params{title} // '';
   my $body            = $params{body} or die "body missing for comment";

   my $json_metadata   = $params{json_metadata} // {};
   if( ref $json_metadata ){
      $json_metadata = encode_json( $json_metadata);
   }

   my $author = $self->get_key_references([$self->public_posting_key])->[0][0];

   my $operation = [
      comment => {
         "parent_author"   => $parent_author,
         "parent_permlink" => $parent_permlink,
         "author"          => $author,
         "permlink"        => $permlink,
         "title"           => $title,
         "body"            => $body,
         "json_metadata"   => $json_metadata,
      }
   ];
   return $self->_broadcast_transaction($operation);
}

=head2 delete_comment

   $steem->delete_comment(
      author => $author,
      permlink => $permlink
   )

you need the permlink
author will be filled with the user of your posting key if missing

=cut

sub delete_comment {
   my( $self, %params ) = @_;

   my $permlink = $params{permlink} or die "permlink missing for comment";

   my $author   = $params{author} // $self->get_key_references([$self->public_posting_key])->[0][0];

   my $operation = [
      delete_comment => {
            "author"          => $author,
            "permlink"        => $permlink,
      }
   ];
   return $self->_broadcast_transaction($operation);
}

=head2 delta_steem_time( $steem_time, $delta_seconds )

the method will take a steem timestam in the format '2018-02-24T16:17:09' like returned in many api calls and add $delta_seconds to it.
can also be negative to travel into the past

=cut

sub delta_steem_time {
   my( $self, $steem_time, $delta_seconds ) = @_;
   return $self->epoch_to_steem_time(
      $self->steem_time_to_epoch( $steem_time ) + $delta_seconds
   )
}

=head2 steem_time_to_epoch( $steem_time )

takes a steem time format and returns the unit time in seconds

=cut

sub steem_time_to_epoch {
   my( $self, $steem_time ) = @_;
   my ($year,$month,$day, $hour,$min,$sec) = split /\D/, $steem_time;
   require Date::Calc;
   my $epoch = eval{ Date::Calc::Date_to_Time($year,$month,$day, $hour,$min,$sec) } or confess $steem_time.$@;
   return $epoch;
}

=head2 epoch_to_steem_time( $epoch )

take the epoch like returned by the time() functiona nd convert it to the steem time format

=cut

sub epoch_to_steem_time {
   my( $self, $epoch ) = @_;
   require Date::Calc;
   my ($year,$month,$day, $hour,$min,$sec) = eval{ Date::Calc::Time_to_Date($epoch) } or cofess $@;
   return  sprintf("%04d-%02d-%02dT%02d:%02d:%02d",$year,$month,$day,$hour,$min,$sec);
}

=head2 limit_order_create

this will create a market order to sell some item for something else

   my $steem = Steemit::WsClient->new( active_key => 'copy from website' );

   $steem->limit_order_create(
      amount_to_sell => "0.001 STEEM",
      min_to_receive => "0.300 SBD",
   )

Further optional parameters are

fill_or_kill => default false, if given a (perl true value ) i guess the order has to be completely filled in one go or will not fill at all
orderid     => defaults to the current time epoch, you can however give a value in, this will be usefull for canceling the order again
expiration   => defaults to "2060-02-07T06:28:15" and needs the saem format, if you encounte this as a bug because this timestamp is in the past well done sir. You have earned the chief archiological code award of the month

please note that the amounts need to have exactly 3 prcition numbers

=cut

sub limit_order_create {
   my( $self, %order ) = @_;

   my $owner = $self->get_key_references([$self->public_active_key])->[0][0];

   return $self->_broadcast_transaction_active([
      limit_order_create => {
       "owner"          => $owner,
       "orderid"        => $order{orderid} // time()."",
       "amount_to_sell" => $order{amount_to_sell} // die("amount_to_sell missing"),
       "min_to_receive" => $order{min_to_receive} // die("min_to_receive missing"),
       "fill_or_kill"   => $order{fill_or_kill} ? 'true' : 'false',
       "expiration"     => $order{expiration} // "2030-02-07T06:28:15",
   }]);
}


=head2 limit_order_cancel

will cancel a exiting order based on the order_id

   $steem->limit_order_cancel(
      orderid => 1234
   );

=cut

sub limit_order_cancel {
   my( $self, %order ) = @_;

   my $owner = $self->get_key_references([$self->public_active_key])->[0][0];

   $self->_broadcast_transaction_active([
      limit_order_cancel => {
       "owner" => $owner,
       "orderid" => $order{orderid} // die "orderid missing"
   }]);
}

=head2 claim_reward_balance

this method will let you redeem rewards you have pengind from the network.

call it like this:

   $steem->claim_reward_balance(
      account      => 'your name',
      reward_steem => "0.10 STEEM",
      reward_sbd   => "0.20 SBD",
      reward_vests => "0.300000 VESTS",
   )

the current amount you can clam can be gathered via the $steem->get_accounts(['your name'])
call and will then be present in the fields:

            'reward_steem_balance'   => '0.000 STEEM',
            'reward_sbd_balance'     => '20.169 SBD',
            'reward_vesting_balance' => '17071.539655 VESTS',


=cut


sub claim_reward_balance {
   my( $self, %amounts ) = @_;

   $self->_broadcast_transaction_active([
      claim_reward_balance => {
       account      => $amounts{account}      // $self->get_key_references([$self->public_active_key])->[0][0],
       reward_steem => $amounts{reward_steem} // "0.000 STEEM",
       reward_sbd   => $amounts{reward_sbd}   // "0.000 SBD",
       reward_vests => $amounts{reward_vests} // "0.000000 VESTS",
   }]);
}


=head2 get_open_orders(owner)

will return you the current open orders for a person ( i.e you ;)

   $VAR1 = [
          {
            'sell_price' => {
                              'base' => '0.010 STEEM',
                              'quote' => '0.030 SBD'
                            },
            'real_price' => '3.00000000000000000',
            'seller' => 'hoffmann',
            'for_sale' => 10,
            'orderid' => 1234,
            'id' => 1925750,
            'rewarded' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
            'created' => '2018-03-10T07:51:39',
            'expiration' => '2030-02-07T06:28:15'
          }
        ];


=cut

=head2 get_order_book($limit)

will return you the current open market orders in the following format:

     $VAR1 = {
          'bids' => [
                      {
                        'real_price' => '1.02360056051331227',
                        'steem' => 13559,
                        'order_price' => {
                                           'base' => '13.879 SBD',
                                           'quote' => '13.559 STEEM'
                                         },
                        'sbd' => 13879,
                        'created' => '2018-03-10T07:46:06'
                      }
                    ],
          'asks' => [
                      {
                        'steem' => 162929,
                        'real_price' => '1.02368409343715250',
                        'order_price' => {
                                           'base' => '449.500 STEEM',
                                           'quote' => '460.146 SBD'
                                         },
                        'sbd' => 166787,
                        'created' => '2018-03-10T07:25:21'
                      }
                    ]
        };

=cut


=head2 transfer

allows you to transfer assets to other users

   $steem->transfer(
      from      => '<you>',
      to        => 'reciving account',
      amount    => "0.001 SBD",
      memo      => 'some text',
   )

from is optional and will be filled with the user assiciated with your public active key
memo can also be lenft blank

amounst can either be in the form
1.234 STEEM
2.345 SBD

VESTS cant be sent currently. please take care to have the correct amount of digits after the comma

=cut

sub transfer {
   my( $self, %transfer ) = @_;

   $self->_broadcast_transaction_active([
      transfer => {
         from   => $transfer{from}      // $self->get_key_references([$self->public_active_key])->[0][0],
         to     => $transfer{to}        // die("to missing"),
         amount => $transfer{amount}    // die("amount missing"),
         memo   => $transfer{memo}      //'',
   }]);
}



sub _broadcast_transaction {
   my( $self, @operations ) = @_;

   return $self->_broadcast_transaction_with_keys( $self->plain_posting_key, @operations );
}

sub _broadcast_transaction_active {
   my( $self, @operations ) = @_;

   return $self->_broadcast_transaction_with_keys( $self->plain_active_key, @operations );
}


sub _broadcast_transaction_with_keys {
   my( $self, $private_key, @operations ) = @_;

   my $properties = $self->get_dynamic_global_properties();

   my $block_number  = $properties->{last_irreversible_block_num};
   my $block_details = $self->get_block( $block_number );

   my $ref_block_id  = $block_details->{previous},

   my $expiration    = $self->delta_steem_time($properties->{time},600);

   my $transaction = {
      ref_block_num => ( $block_number - 1 )& 0xffff,
      ref_block_prefix => unpack( "xxxxV", pack('H*',$ref_block_id)),
      expiration       => $expiration,
      operations       => [@operations],
      extensions => [],
      signatures => [],
   };
   my $serialized_transaction = $self->_serialize_transaction_message( $transaction );

   my $bin_private_key = $private_key;
   require Steemit::ECDSA;
   my ( $r, $s, $i ) = Steemit::ECDSA::ecdsa_sign( $serialized_transaction, Math::BigInt->from_bytes( $bin_private_key ) );
   $i += 4;
   $i += 27;

   my $signature = join('', map { unpack 'H*', $_ } ( pack("C", $i ), map { $_->as_bytes} ($r,$s )) );
   unless( Steemit::ECDSA::is_signature_canonical_canonical( pack "H*", $signature ) ){
      die "signature $signature is not canonical";
   }

   $transaction->{signatures} = [ $signature ];


   $self->_request('network_broadcast_api','broadcast_transaction_synchronous',$transaction);
}

sub public_active_key {
   my( $self ) = @_;
   unless( $self->{public_active_key} ){
      $self->{public_active_key} = $self->_private_key_to_adress( $self->plain_active_key );
   }

   return $self->{public_active_key}
}

sub public_posting_key {
   my( $self ) = @_;
   unless( $self->{public_posting_key} ){
      $self->{public_posting_key} = $self->_private_key_to_adress( $self->plain_posting_key );
   }

   return $self->{public_posting_key}
}

sub _private_key_to_adress {
   my( $self, $private_key ) = @_;
   require Steemit::ECDSA;
   my $bin_pubkey = Steemit::ECDSA::get_compressed_public_key( Math::BigInt->from_bytes( $private_key ) );
   #TODO use the STM from dynamic lookup in get_config or somewhere
   require Crypt::RIPEMD160;
   my $rip = Crypt::RIPEMD160->new;
   $rip->reset;
   $rip->add($bin_pubkey);
   my $checksum = $rip->digest;
   $rip->reset;
   $rip->add('');
   return "STM".Steemit::Base58::encode_base58($bin_pubkey.substr($checksum,0,4));
}

sub _transform_private_key_active {
   my( $self ) = @_;
   die "active_key missing" unless( $self->active_key );

   my $base58 = $self->active_key;

   require Steemit::Base58;
   my $binary = Steemit::Base58::decode_base58( $base58 );


   my $version            = substr( $binary, 0, 1 );
   my $binary_private_key = substr( $binary, 1, -4);
   my $checksum           = substr( $binary, -4);
   die "invalid version in wif ( 0x80 needed ) " unless $version eq  pack "H*", '80';

   require Digest::SHA;
   my $generated_checksum = substr( Digest::SHA::sha256( Digest::SHA::sha256( $version.$binary_private_key )), 0, 4 );

   die "invalid checksum " unless $generated_checksum eq $checksum;

   return $binary_private_key;
}


sub _transform_private_key {
   my( $self ) = @_;
   die "posting_key missing" unless( $self->posting_key );

   my $base58 = $self->posting_key;

   require Steemit::Base58;
   my $binary = Steemit::Base58::decode_base58( $base58 );


   my $version            = substr( $binary, 0, 1 );
   my $binary_private_key = substr( $binary, 1, -4);
   my $checksum           = substr( $binary, -4);
   die "invalid version in wif ( 0x80 needed ) " unless $version eq  pack "H*", '80';

   require Digest::SHA;
   my $generated_checksum = substr( Digest::SHA::sha256( Digest::SHA::sha256( $version.$binary_private_key )), 0, 4 );

   die "invalid checksum " unless $generated_checksum eq $checksum;

   return $binary_private_key;
}

sub _serialize_transaction_message  {
   my ($self,$transaction) = @_;

   my $serialized_transaction;

   $serialized_transaction .= pack 'v', $transaction->{ref_block_num};

   $serialized_transaction .= pack 'V', $transaction->{ref_block_prefix};

   $serialized_transaction .= pack 'L', $self->steem_time_to_epoch( $transaction->{expiration} );

   $serialized_transaction .= pack "C", scalar( @{ $transaction->{operations} });

   require Steemit::OperationSerializer;
   my $op_ser = Steemit::OperationSerializer->new;

   for my $operation ( @{ $transaction->{operations} } ) {

      my ($operation_name,$operations_parameters) = @$operation;
      $serialized_transaction .= $op_ser->serialize_operation(
         $operation_name,
         $operations_parameters,
      );
   }

   #extentions in case we realy need them at some point we will have to implement this is a less nive way ;)
   die "extentions not supported" if $transaction->{extensions} and $transaction->{extensions}[0];
   $serialized_transaction .= pack 'H*', '00';

   return pack( 'H*', ( '0' x 64 )).$serialized_transaction;
}






=head1 REPOSITORY

L<https://github.com/snkoehn/perlSteemit>


=head1 AUTHOR

snkoehn, C<< <snkoehn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-steemit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit::WsClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Steemit::WsClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Steemit::WsClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Steemit::WsClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 snkoehn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Steemit::WsClient
