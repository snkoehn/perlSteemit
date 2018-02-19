package Steemit;

use Modern::Perl '2017';
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);

has url     => 'https://rpc.steemliberator.com';
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

install_methods();

sub install_methods {
   my %definition = _get_api_definition();
   for my $api ( keys %definition ){
      for my $method ( $definition{$api}->@* ){
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
   );

   return (
      database_api          => [@database_api],
   )
}

1;