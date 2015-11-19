module Braintree
  class Transaction
    class VenmoAccountDetails
      include BaseModule

      attr_reader :username, :venmo_user_id, :token, :source_description, :image_url

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
