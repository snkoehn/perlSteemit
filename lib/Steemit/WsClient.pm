package Steemit::WsClient;

=head1 NAME

Steemit::WsClient - perl lirary for interacting with the steemit websocket services!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Steemit::WsClient;

    my $foo = Steemit->new();
    my $steem = Steemit->new( url => 'https://some.steemit.d.node.address');

    say "Initialized Steemit client with url ".$steem->url;

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


=head1 SUBROUTINES/METHODS

=cut

use Modern::Perl;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);

has url     => 'https://steemd.steemitstage.com';
has ua      =>  sub { Mojo::UserAgent->new };


=head2 installes all database api methods of the steemit api

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

=cut

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

_install_methods();

sub _install_methods {
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
sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

snkoehn, C<< <koehn.sebastian at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-steemit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Steemit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Steemit>

=item * Search CPAN

L<http://search.cpan.org/dist/Steemit/>

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

1; # End of Steemit
