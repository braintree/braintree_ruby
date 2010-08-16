require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::TransparentRedirect do
  describe "self.create_credit_card_data" do
    it "raises an exception if any keys are invalid" do
      expect do
        Braintree::TransparentRedirect.create_credit_card_data(
          :credit_card => {:number => "ok", :invalid_key => "bad"}
        )
      end.to raise_error(ArgumentError, "invalid keys: credit_card[invalid_key]")
    end
  end

  describe "self.create_customer_data" do
    it "raises an exception if any keys are invalid" do
      expect do
        Braintree::TransparentRedirect.create_customer_data(
          :customer => {:first_name => "ok", :invalid_key => "bad"}
        )
      end.to raise_error(ArgumentError, "invalid keys: customer[invalid_key]")
    end
  end

  describe "self.parse_and_validate_query_string" do
    it "returns the parsed query string params if the hash is valid" do
      query_string_without_hash = "one=1&two=2&http_status=200"
      hash = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, query_string_without_hash)

      query_string_with_hash = "#{query_string_without_hash}&hash=#{hash}"
      result = Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string query_string_with_hash
      result.should == {:one => "1", :two => "2", :http_status => "200", :hash => hash}
    end

    it "raises Braintree::ForgedQueryString if the hash param is not valid" do
      query_string_without_hash = "http_status=200&one=1&two=2"
      hash = Digest::SHA1.hexdigest("invalid#{query_string_without_hash}")

      query_string_with_hash = "#{query_string_without_hash}&hash=#{hash}"
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string query_string_with_hash
      end.to raise_error(Braintree::ForgedQueryString)
    end

    it "raises Braintree::ForgedQueryString if hash is missing from the query string" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string "http_status=200&query_string=without_a_hash"
      end.to raise_error(Braintree::ForgedQueryString)
    end

    it "raises an AuthenticationError if authentication fails" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string add_hash_to_query_string("http_status=401")
      end.to raise_error(Braintree::AuthenticationError)
    end

    it "raises an AuthorizationError if authorization fails" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string add_hash_to_query_string("http_status=403")
      end.to raise_error(Braintree::AuthorizationError)
    end

    it "raises an UnexpectedError if http_status is not in query string" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string add_hash_to_query_string("no_http_status=x")
      end.to raise_error(Braintree::UnexpectedError, "expected query string to have an http_status param")
    end

    it "raises a ServerError if the server 500's" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string add_hash_to_query_string("http_status=500")
      end.to raise_error(Braintree::ServerError)
    end

    it "raises a DownForMaintenanceError if the server is down for maintenance" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string add_hash_to_query_string("http_status=503")
      end.to raise_error(Braintree::DownForMaintenanceError)
    end

    it "raises an UnexpectedError if some other code is returned" do
      expect do
        Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string add_hash_to_query_string("http_status=600")
      end.to raise_error(Braintree::UnexpectedError, "Unexpected HTTP_RESPONSE 600")
    end
  end

  describe "self.transaction_data" do
    it "raises an exception if any keys are invalid" do
      expect do
        Braintree::TransparentRedirect.transaction_data(
          :transaction => {:amount => "100.00", :invalid_key => "bad"}
        )
      end.to raise_error(ArgumentError, "invalid keys: transaction[invalid_key]")
    end

    it "raises an exception if not given a type" do
      expect do
        Braintree::TransparentRedirect.transaction_data(
          :redirect_url => "http://example.com",
          :transaction => {:amount => "100.00"}
        )
      end.to raise_error(ArgumentError, "expected transaction[type] of sale or credit, was: nil")
    end

    it "raises an exception if not given a type of sale or credit" do
      expect do
        Braintree::TransparentRedirect.transaction_data(
          :redirect_url => "http://example.com",
          :transaction => {:amount => "100.00", :type => "auth"}
        )
      end.to raise_error(ArgumentError, "expected transaction[type] of sale or credit, was: \"auth\"")
    end
  end

  describe "self.update_credit_card_data" do
    it "raises an exception if any keys are invalid" do
      expect do
        Braintree::TransparentRedirect.update_credit_card_data(
          :credit_card => {:number => "ok", :invalid_key => "bad"}
        )
      end.to raise_error(ArgumentError, "invalid keys: credit_card[invalid_key]")
    end

    it "raises an exception if not given a payment_method_token" do
      expect do
        Braintree::TransparentRedirect.update_credit_card_data({})
      end.to raise_error(ArgumentError, "expected params to contain :payment_method_token of payment method to update")
    end
  end

  describe "self.update_customer_data" do
    it "raises an exception if any keys are invalid" do
      expect do
        Braintree::TransparentRedirect.update_customer_data(
          :customer => {:first_name => "ok", :invalid_key => "bad"}
        )
      end.to raise_error(ArgumentError, "invalid keys: customer[invalid_key]")
    end

    it "raises an exception if not given a customer_id" do
      expect do
        Braintree::TransparentRedirect.update_customer_data({})
      end.to raise_error(ArgumentError, "expected params to contain :customer_id of customer to update")
    end
  end

  describe "self._data" do
    it "raises an exception if :redirect_url isn't given" do
      expect do
        Braintree::TransparentRedirect.create_customer_data(:redirect_url => nil)
      end.to raise_error(ArgumentError, "expected params to contain :redirect_url")
    end
  end

  def add_hash_to_query_string(query_string_without_hash)
    hash = Braintree::Configuration.gateway.transparent_redirect._hash(query_string_without_hash)
    query_string_without_hash + "&hash=" + hash
  end
end

