require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Customer do
  describe "inspect" do
    it "includes the id first" do
      output = Braintree::Customer._new(:gateway, {:first_name => 'Dan', :id => '1234'}).inspect
      output.should include("#<Braintree::Customer id: \"1234\",")
    end

    it "includes all customer attributes" do
      customer = Braintree::Customer._new(
        :gateway,
        :company => "Company",
        :email => "e@mail.com",
        :fax => "483-438-5821",
        :first_name => "Patrick",
        :last_name => "Smith",
        :phone => "802-483-5932",
        :website => "patrick.smith.com",
        :created_at => Time.now,
        :updated_at => Time.now
      )
      output = customer.inspect
      output.should include(%q(company: "Company"))
      output.should include(%q(email: "e@mail.com"))
      output.should include(%q(fax: "483-438-5821"))
      output.should include(%q(first_name: "Patrick"))
      output.should include(%q(last_name: "Smith"))
      output.should include(%q(phone: "802-483-5932"))
      output.should include(%q(website: "patrick.smith.com"))
      output.should include(%Q(created_at: #{customer.created_at.inspect}))
      output.should include(%Q(updated_at: #{customer.updated_at.inspect}))
    end
  end

  describe "self.create" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Customer.create(:first_name => "Joe", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.update" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Customer.update("customer_id", :first_name => "Joe", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create_signature" do
    it "should be what we expect" do
      Braintree::CustomerGateway._create_signature.should == [
        :company,
        :email,
        :fax,
        :first_name,
        :id,
        :last_name,
        :phone,
        :website,
        {:credit_card => [
          :cardholder_name,
          :cvv,
          :expiration_date,
          :expiration_month,
          :expiration_year,
          :number,
          :token,
          {:options => [:make_default, :verification_merchant_account_id, :verify_card]},
          {:billing_address => [
            :company,
            :country_code_alpha2,
            :country_code_alpha3,
            :country_code_numeric,
            :country_name,
            :extended_address,
            :first_name,
            :last_name,
            :locality,
            :postal_code,
            :region,
            :street_address
          ]}
        ]},
        {:custom_fields => :_any_key_}
      ]
    end
  end

  describe "self.update_signature" do
    it "should be what we expect" do
      Braintree::CustomerGateway._update_signature.should == [
        :company,
        :email,
        :fax,
        :first_name,
        :id,
        :last_name,
        :phone,
        :website,
        {:credit_card => [
          :cardholder_name,
          :cvv,
          :expiration_date,
          :expiration_month,
          :expiration_year,
          :number,
          :token,
          {:options => [
            :make_default,
            :verification_merchant_account_id,
            :verify_card,
            :update_existing_token
          ]},
          {:billing_address => [
            :company,
            :country_code_alpha2,
            :country_code_alpha3,
            :country_code_numeric,
            :country_name,
            :extended_address,
            :first_name,
            :last_name,
            :locality,
            :postal_code,
            :region,
            :street_address,
            {:options => [:update_existing]}
          ]}
        ]},
        {:custom_fields => :_any_key_}
      ]
    end
  end

  describe "self.create_from_transparent_redirect" do
    it "raises an exception if the query string is forged" do
      expect do
        Braintree::Customer.create_from_transparent_redirect("http_status=200&forged=query_string")
      end.to raise_error(Braintree::ForgedQueryString)
    end
  end

  describe "==" do
    it "returns true when given a customer with the same id" do
      first = Braintree::Customer._new(:gateway, :id => 123)
      second = Braintree::Customer._new(:gateway, :id => 123)

      first.should == second
      second.should == first
    end

    it "returns false when given a customer with a different id" do
      first = Braintree::Customer._new(:gateway, :id => 123)
      second = Braintree::Customer._new(:gateway, :id => 124)

      first.should_not == second
      second.should_not == first
    end

    it "returns false when not given a customer" do
      customer = Braintree::Customer._new(:gateway, :id => 123)
      customer.should_not == "not a customer"
    end
  end

  describe "initialize" do
    it "converts payment method hashes into payment method objects" do
      customer = Braintree::Customer._new(
        :gateway,
        :credit_cards => [
          {:token => "pm1"},
          {:token => "pm2"}
        ]
      )
      customer.credit_cards.size.should == 2
      customer.credit_cards[0].token.should == "pm1"
      customer.credit_cards[1].token.should == "pm2"
    end
  end

  describe "new" do
    it "is protected" do
      expect do
        Braintree::Customer.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
