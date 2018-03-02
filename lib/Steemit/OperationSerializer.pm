package Steemit::OperationSerializer;
use Modern::Perl;

sub new {
   my( $class, %params ) = @_;
   my $self = {};
   return bless $self, $class;

}


sub serialize_operation {
   my( $self, $operation_name, $operation_parameters ) = @_;
   ##operation id

   if( my $serializer_method = $self->can("serialize_$operation_name") ){
      return $serializer_method->($self,$operation_name,$operation_parameters);
   }else{
      die "operation $operation_name currently not support for serialisation";
   }

}

sub serialize_vote {
   my( $self, $operation_name, $operation_parameters ) = @_;

   my $serialized_operation = '';
   my $operation_id = $self->_index_of_operation($operation_name);
   $serialized_operation .= pack "C", $operation_id;

   $serialized_operation .= pack "C", length $operation_parameters->{voter};
   $serialized_operation .= pack "A*", $operation_parameters->{voter};

   $serialized_operation .= pack "C", length $operation_parameters->{author};
   $serialized_operation .= pack "A*", $operation_parameters->{author};

   $serialized_operation .= pack "C", length $operation_parameters->{permlink};
   $serialized_operation .= pack "A*", $operation_parameters->{permlink};

   $serialized_operation .= pack "s", $operation_parameters->{weight};


   return $serialized_operation;


}




sub _index_of_operation {
   my ( $self, $operation ) = @_;

   #https://github.com/steemit/steem-js/blob/master/src/auth/serializer/src/operations.js#L767
   my @operations = qw(
   vote
   comment
   transfer
   transfer_to_vesting
   withdraw_vesting
   limit_order_create
   limit_order_cancel
   feed_publish
   convert
   account_create
   account_update
   witness_update
   account_witness_vote
   account_witness_proxy
   pow
   custom
   report_over_production
   delete_comment
   custom_json
   comment_options
   set_withdraw_vesting_route
   limit_order_create2
   challenge_authority
   prove_authority
   request_account_recovery
   recover_account
   change_recovery_account
   escrow_transfer
   escrow_dispute
   escrow_release
   pow2
   escrow_approve
   transfer_to_savings
   transfer_from_savings
   cancel_transfer_from_savings
   custom_binary
   decline_voting_rights
   reset_account
   set_reset_account
   claim_reward_balance
   delegate_vesting_shares
   account_create_with_delegation
   fill_convert_request
   author_reward
   curation_reward
   comment_reward
   liquidity_reward
   interest
   fill_vesting_withdraw
   fill_order
   shutdown_witness
   fill_transfer_from_savings
   hardfork
   comment_payout_update
   return_vesting_delegation
   comment_benefactor_reward
   );
   unless( $self->{_op_index} ){
      my $count = 0;
      $self->{_op_index} = { map { $_ => $count++ } @operations };
   }
   return $self->{_op_index}{$operation} // die "$operation not defined";

}



1;
