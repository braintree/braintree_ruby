require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/spec_helper")


describe Braintree::ClientToken do
  describe "self.generate" do
    it "generates a fingerprint that the gateway accepts" do
      config = Braintree::Configuration.instantiate
      raw_client_token = Braintree::ClientToken.generate
      client_token = decode_client_token(raw_client_token)
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => client_token["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.get_payment_methods

      expect(response.code).to eq("200")
    end

    describe "domains" do
      it "allows a domain to be specified" do
        client_token_string = Braintree::ClientToken.generate(:domains => ["example.com"])
        client_token = decode_client_token(client_token_string)
        authorization_fingerprint = Base64.decode64(client_token["authorizationFingerprint"])
        expect(authorization_fingerprint.include? "example.com").to eq(true)
      end

      it "raises ClientTokenTooManyDomains on too many domains" do
        expect do
          Braintree::ClientToken.generate(
            :domains => ["example1.com",
              "example2.com",
              "example3.com",
              "example4.com",
              "example5.com",
              "example6.com"
            ])
        end.to raise_error(ArgumentError, "Cannot specify more than 5 client token domains")
      end

      it "raises ClientTokenInvalidDomainFormat on invalid format" do
        expect do
          Braintree::ClientToken.generate(:domains => ["example"])
        end.to raise_error(ArgumentError, "Client token domains must be valid domain names (RFC 1035), e.g. example.com")
      end
    end

    it "raises ArgumentError on invalid parameters (422)" do
      expect do
        Braintree::ClientToken.generate(:options => {:make_default => true})
      end.to raise_error(ArgumentError)
    end

    describe "version" do
      it "allows a client token version to be specified" do
        client_token_string = Braintree::ClientToken.generate(:version => 1)
        client_token = JSON.parse(client_token_string)
        expect(client_token["version"]).to eq(1)
      end

      it "defaults to 2" do
        client_token_string = Braintree::ClientToken.generate
        client_token = decode_client_token(client_token_string)
        expect(client_token["version"]).to eq(2)
      end
    end

    it "can pass verify_card" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      raw_client_token = Braintree::ClientToken.generate(
        :customer_id => result.customer.id,
        :options => {
          :verify_card => true
        },
      )
      client_token = decode_client_token(raw_client_token)

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => client_token["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.add_payment_method(
        :credit_card => {
          :number => "4000111111111115",
          :expiration_month => "11",
          :expiration_year => "2099"
        },
      )

      expect(response.code).to eq("422")
    end

    it "can pass make_default" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      customer_id = result.customer.id
      raw_client_token = Braintree::ClientToken.generate(
        :customer_id => customer_id,
        :options => {
          :make_default => true
        },
      )
      client_token = decode_client_token(raw_client_token)

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => client_token["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.add_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        },
      )

      expect(response.code).to eq("201")

      response = http.add_payment_method(
        :credit_card => {
          :number => "4005519200000004",
          :expiration_month => "11",
          :expiration_year => "2099"
        },
      )

      expect(response.code).to eq("201")

      customer = Braintree::Customer.find(customer_id)
      expect(customer.credit_cards.select { |c| c.bin == "400551" }[0]).to be_default
    end

    it "can pass fail_on_duplicate_payment_method" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      customer_id = result.customer.id
      raw_client_token = Braintree::ClientToken.generate(
        :customer_id => customer_id,
      )
      client_token = decode_client_token(raw_client_token)

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => client_token["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.add_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        },
      )

      expect(response.code).to eq("201")

      second_raw_client_token = Braintree::ClientToken.generate(
        :customer_id => customer_id,
        :options => {
          :fail_on_duplicate_payment_method => true
        },
      )
      second_client_token = decode_client_token(second_raw_client_token)

      http.fingerprint = second_client_token["authorizationFingerprint"]

      response = http.add_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        },
      )

      expect(response.code).to eq("422")
    end

    it "can pass merchant_account_id" do
      merchant_account_id = SpecHelper::NonDefaultMerchantAccountId

      raw_client_token = Braintree::ClientToken.generate(
        :merchant_account_id => merchant_account_id,
      )
      client_token = decode_client_token(raw_client_token)

      expect(client_token["merchantAccountId"]).to eq(merchant_account_id)
    end

    context "paypal" do
      it "includes the paypal options for a paypal merchant" do
        with_altpay_merchant do
          raw_client_token = Braintree::ClientToken.generate
          client_token = decode_client_token(raw_client_token)

          expect(client_token["paypal"]["displayName"]).to eq("merchant who has paypal and sepa enabled")
          expect(client_token["paypal"]["clientId"]).to match(/.+/)
          expect(client_token["paypal"]["privacyUrl"]).to match("http://www.example.com/privacy_policy")
          expect(client_token["paypal"]["userAgreementUrl"]).to match("http://www.example.com/user_agreement")
          expect(client_token["paypal"]["baseUrl"]).not_to be_nil
        end
      end
    end
  end
end
