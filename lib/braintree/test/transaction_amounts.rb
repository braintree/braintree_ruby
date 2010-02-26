module Braintree
  module Test # :nodoc:
    # The constants in this module can be used to create transactions with
    # the desired status in the sandbox environment.
    module TransactionAmounts
      Authorize = "1000.00"
      Decline = "2000.00"
    end

    module Plans
      TrialPlan = {
        :description => "Plan for integration tests -- with trial",
        :id => "integration_trial_plan",
        :price => "43.21",
        :trial_period => true,
        :trial_duration => 2,
        :trial_duration_unit => Subscription::TrialDurationUnit::Day
      }

      TriallessPlan = {
        :description => "Plan for integration tests -- without a trial",
        :id => "integration_trialless_plan",
        :price => "12.34",
        :trial_period => false
      }
    end
  end
end
