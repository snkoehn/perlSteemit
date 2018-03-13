
#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 9;

use_ok( 'Steemit::OperationSerializer' ) || print "Bail out!\n";

my $serializer = Steemit::OperationSerializer->new;

isa_ok( $serializer, 'Steemit::OperationSerializer', 'constructor works');

my $vote_operation = [
   vote => {
      voter    => 'voterr',
      author   => 'authorrr',
      permlink => 'permliiiiing',
      weight   => 596,
   }
];

my $vote_serialisation = '0006766f7465727208617574686f7272720c7065726d6c69696969696e675402';

is( unpack( "H*",$serializer->serialize_operation(@$vote_operation)), $vote_serialisation, "vote serialisation is correct");


my $comment_operation = [
   comment => {
         "parent_author"   => 'sime-guy',
         "parent_permlink" => 'important_post-siming-something',
         "author"          => 'itsa_me_mario',
         "permlink"        => 're-important_post-siming-something.time()',
         "title"           => '',
         "body"            => 'wow nice post',
         "json_metadata"   => '{ "tags" => ["utopian-io"]}',
   }
];

my $comment_seroalisation = '010873696d652d6775791f696d706f7274616e745f706f73742d73696d696e672d736f6d657468696e670d697473615f6d655f6d6172696f2972652d696d706f7274616e745f706f73742d73696d696e672d736f6d657468696e672e74696d652829000d776f77206e69636520706f73741b7b20227461677322203d3e205b2275746f7069616e2d696f225d7d';
is( unpack( "H*",$serializer->serialize_operation(@$comment_operation)), $comment_seroalisation, "comment serialisation is correct");



my $delete_comment_operation = [
   delete_comment => {
         "author"          => 'itsa_me_mario',
         "permlink"        => 're-important_post-siming-something.time()',
   }
];

my $delete_comment_operation_serial = '110d697473615f6d655f6d6172696f2972652d696d706f7274616e745f706f73742d73696d696e672d736f6d657468696e672e74696d652829';
is( unpack( "H*",$serializer->serialize_operation(@$delete_comment_operation)), $delete_comment_operation_serial, "delete_comment serialisation is correct");

my $limit_order_operation = [
   limit_order_create => {
      "owner" => "waleofwhales",
      "orderid" => 1520329,
      "amount_to_sell" => "0.041 STEEM",
      "min_to_receive" => "0.082 SBD",
      "fill_or_kill" => 'false',
      "expiration" => "2020-02-07T06:28:15"
   }];

my $serialized_limit_order = '050c77616c656f667768616c6573c9321700290000000000000003535445454d000052000000000000000353424400000000007f033d5e';
is( unpack( "H*", $serializer->serialize_operation(@$limit_order_operation)), $serialized_limit_order, " limit_order_create serialisation is correct");


my $cancel_order_operation = [
   limit_order_cancel => {
      "owner" => "waleofwhales",
      "orderid" => 1520329,
   }];

my $serialized_cancel_order = '060c77616c656f667768616c6573c9321700';
is( unpack( "H*", $serializer->serialize_operation(@$cancel_order_operation)), $serialized_cancel_order, " cancel_order serialisation is correct");


my $claim_reward_balance = [
   claim_reward_balance => {
      account      => 'your name',
      reward_steem => "0.00 STEEM",
      reward_sbd   => "0.00 SBD",
      reward_vests => "0.000000 VESTS",
   }
];

my $claim_reward_balance_serialized = '2709796f7572206e616d65000000000000000003535445454d00000000000000000000035342440000000000000000000000000656455354530000';

is( unpack( "H*", $serializer->serialize_operation(@$claim_reward_balance)), $claim_reward_balance_serialized, " claim_reward_balance serialisation is correct");



my $transfer = [
   transfer => {
      from => 'hans',
      to   => 'peter',
      amount => '1.234 STEEM',
      memo   => 'memorandum'
   }
];

my $transfer_serialized = '020468616e73057065746572d20400000000000003535445454d00000a6d656d6f72616e64756d';

is( unpack( "H*", $serializer->serialize_operation(@$transfer)), $transfer_serialized, " transfer serialisation is correct");



