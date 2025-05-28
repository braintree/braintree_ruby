# Represents the customer recommendations information associated with a PayPal customer session.

#Experimental
# This class is experimental and may change in future releases.
module Braintree
  class CustomerRecommendationsPayload
    include BaseModule

    attr_reader :attrs
    attr_reader :is_in_paypal_network
    attr_reader :recommendations

    def initialize(attributes)
      @attrs = [:is_in_paypal_network, :recommendations]

      if attributes.key?(:response)
        response = attributes[:response]
        # Constructor for response map
        begin
          @is_in_paypal_network = _get_value(response, "generateCustomerRecommendations.isInPayPalNetwork")
          @recommendations = _extract_recommendations(response)
        rescue => e
          puts e.backtrace.join("\n")
          raise
        end
      else
        @is_in_paypal_network = attributes[:is_in_paypal_network]
        @recommendations = attributes[:recommendations]
      end
    end

    def _extract_recommendations(response)
      begin
        payment_recommendations = _get_value(response, "generateCustomerRecommendations.paymentRecommendations")

        payment_options_list = []
        payment_recommendations_list = []

        payment_recommendations.each_with_index do |recommendation, _i|
          recommended_priority = _get_value(recommendation, "recommendedPriority")
          payment_option_string = _get_value(recommendation, "paymentOption")

          begin
            payment_option = payment_option_string

            payment_option_obj = Braintree::PaymentOptions._new({
              paymentOption: payment_option,
              recommendedPriority: recommended_priority
            })

            payment_recommendation_obj = Braintree::PaymentRecommendations._new({
              paymentOption: payment_option,
              recommendedPriority: recommended_priority
            })

            payment_options_list << payment_option_obj
            payment_recommendations_list << payment_recommendation_obj
          rescue => e
            puts e.backtrace.join("\n")
            raise
          end
        end

        customer_recommendations = CustomerRecommendations._new({
          payment_recommendations: payment_recommendations_list
        })

        return customer_recommendations
      rescue => e
        puts e.backtrace.join("\n")
        raise ServerError.new("Error extracting recommendations: #{e.message}")
      end
    end

    def _get_value(response, key)
      current_map = response
      key_parts = key.split(".")

      # Navigate through nested dictionaries for all but last key
      (0...key_parts.length - 1).each do |i|
        sub_key = key_parts[i]
        current_map = _pop_value(current_map, sub_key)
      end

      # Get the final value
      last_key = key_parts[-1]
      value = _pop_value(current_map, last_key)
      return value
    end

    def _pop_value(response, key)

    # Try as string first
    if response.key?(key)
        return response[key]
    end

    # Then try as symbol
    symkey = key.to_sym
    if response.key?(symkey)
        return response[symkey]
    end

    # Finally try as string with string keys
    if response.key?(key.to_s)
        return response[key.to_s]
    end

    raise ServerError.new("Couldn't parse response")
    end
    def inspect
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end


