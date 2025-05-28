# A union of all possible customer recommendations associated with a PayPal customer session.

#Experimental
# This class is experimental and may change in future releases.
module Braintree
  class CustomerRecommendations
    include BaseModule

    attr_reader :payment_options, :payment_recommendations

    def initialize(attributes = {})
      @payment_recommendations = initialize_payment_recommendations(attributes[:payment_recommendations])

      # Always derive payment_options from payment_recommendations
      @payment_options = @payment_recommendations.map do |recommendation|
        PaymentOptions._new(
          paymentOption: recommendation.payment_option,
          recommendedPriority: recommendation.recommended_priority,
        )
      end
    end

    def inspect
      "#<#{self.class} payment_options: #{payment_options.inspect}, payment_recommendations: #{payment_recommendations.inspect}>"
    end

    private

    def initialize_payment_recommendations(payment_recommendations)
      return [] if payment_recommendations.nil?

      payment_recommendations.map do |recommendation_hash|
        if recommendation_hash.is_a?(PaymentRecommendations)
          recommendation_hash
        else
          PaymentRecommendations._new(recommendation_hash)
        end
      end
    end

    class << self
      def _new(attributes = {})
        new(attributes)
      end
    end
  end
end