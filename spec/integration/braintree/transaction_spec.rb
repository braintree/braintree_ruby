require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Transaction do
  describe "self.create" do
    it "returns a successful result if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "sale"
      result.transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.processor_authorization_code.should_not be_nil
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2009"
      result.transaction.credit_card_details.customer_location.should == "US"
    end

    it "returns processor response code and text if declined" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "sale"
      result.transaction.status.should == "processor_declined"
      result.transaction.processor_response_code.should == "2000"
      result.transaction.processor_response_text.should == "Do Not Honor"
    end

    it "accepts credit card expiration month and expiration year" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_month => "05",
          :expiration_year => "2011"
        }
      )
      result.success?.should == true
      result.transaction.credit_card_details.expiration_month.should == "05"
      result.transaction.credit_card_details.expiration_year.should == "2011"
      result.transaction.credit_card_details.expiration_date.should == "05/2011"
    end

    it "returns some error if customer_id is invalid" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :customer_id => 123456789
      )
      result.success?.should == false
      result.errors.for(:transaction).on(:customer_id)[0].code.should == "91510"
    end

    it "can create custom fields" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :custom_fields => {
          :store_me => "custom value"
        }
      )
      result.success?.should == true
      result.transaction.custom_fields.should == {:store_me => "custom value"}
    end

    it "returns an error if custom_field is not registered" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :custom_fields => {
          :invalid_key => "custom value"
        }
      )
      result.success?.should == false
      result.errors.for(:transaction).on(:custom_fields)[0].message.should == "Custom field is invalid: invalid_key."
    end

    it "returns the given params if validations fail" do
      params = {
        :transaction => {
          :type => "sale",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.params.should == {:transaction => {:type => 'sale', :amount => nil, :credit_card => {:expiration_date => "05/2009"}}}
    end

    it "returns errors if validations fail (tests many errors at once for spec speed)" do
      params = {
        :transaction => {
          :type => "pants",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :customer_id => "invalid",
          :order_id => "too long" * 250,
          :payment_method_token => "too long and doesn't belong to customer" * 250
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:base).map{|error| error.code}.should include(Braintree::ErrorCodes::Transaction::PaymentMethodConflict)
      result.errors.for(:transaction).on(:base).map{|error| error.code}.should include(Braintree::ErrorCodes::Transaction::PaymentMethodDoesNotBelongToCustomer)
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
      result.errors.for(:transaction).on(:customer_id)[0].code.should == Braintree::ErrorCodes::Transaction::CustomerIdIsInvalid
      result.errors.for(:transaction).on(:order_id)[0].code.should == Braintree::ErrorCodes::Transaction::OrderIdIsTooLong
      result.errors.for(:transaction).on(:payment_method_token)[0].code.should == Braintree::ErrorCodes::Transaction::PaymentMethodTokenIsInvalid
      result.errors.for(:transaction).on(:type)[0].code.should == Braintree::ErrorCodes::Transaction::TypeIsInvalid
    end

    it "returns an error if amount is negative" do
      params = {
        :transaction => {
          :type => "credit",
          :amount => "-1"
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountCannotBeNegative
    end

    it "returns an error if amount is invalid format" do
      params = {
        :transaction => {
          :type => "sale",
          :amount => "shorts"
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsInvalid
    end

    it "returns an error if type is not given" do
      params = {
        :transaction => {
          :type => nil
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:type)[0].code.should == Braintree::ErrorCodes::Transaction::TypeIsRequired
    end

    it "returns an error if no credit card is given" do
      params = {
        :transaction => {
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CreditCardIsRequired
    end

    it "returns an error if the given payment method token doesn't belong to the customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :customer_id => customer.id,
        :payment_method_token => customer.credit_cards[0].token + "x"
      )
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::PaymentMethodDoesNotBelongToCustomer
    end
  end

  describe "self.create!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.create!(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.id.should =~ /^\w{6}$/
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises a validationsfailed if invalid" do
      expect do
        Braintree::Transaction.create!(
          :type => "sale",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.sale" do
    it "returns a successful result with type=sale if successful" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "sale"
      result.transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "works when given all attributes" do
      result = Braintree::Transaction.sale(
        :amount => "100.00",
        :order_id => "123",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2011",
          :cvv => "123"
        },
        :customer => {
          :first_name => "Dan",
          :last_name => "Smith",
          :company => "Braintree Payment Solutions",
          :email => "dan@example.com",
          :phone => "419-555-1234",
          :fax => "419-555-1235",
          :website => "http://braintreepaymentsolutions.com"
        },
        :billing => {
          :first_name => "Carl",
          :last_name => "Jones",
          :company => "Braintree",
          :street_address => "123 E Main St",
          :extended_address => "Suite 403",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60622",
          :country_name => "United States of America"
        },
        :shipping => {
          :first_name => "Andrew",
          :last_name => "Mason",
          :company => "Braintree",
          :street_address => "456 W Main St",
          :extended_address => "Apt 2F",
          :locality => "Bartlett",
          :region => "IL",
          :postal_code => "60103",
          :country_name => "United States of America"
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.id.should =~ /\A\w{6}\z/
      transaction.type.should == "sale"
      transaction.status.should == "authorized"
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.order_id.should == "123"
      transaction.processor_response_code.should == "1000"
      transaction.created_at.between?(Time.now - 5, Time.now).should == true
      transaction.updated_at.between?(Time.now - 5, Time.now).should == true
      transaction.credit_card_details.bin.should == "510510"
      transaction.credit_card_details.last_4.should == "5100"
      transaction.credit_card_details.masked_number.should == "510510******5100"
      transaction.credit_card_details.card_type.should == "MasterCard"
      transaction.avs_error_response_code.should == nil
      transaction.avs_postal_code_response_code.should == "M"
      transaction.avs_street_address_response_code.should == "M"
      transaction.cvv_response_code.should == "M"
      transaction.customer_details.first_name.should == "Dan"
      transaction.customer_details.last_name.should == "Smith"
      transaction.customer_details.company.should == "Braintree Payment Solutions"
      transaction.customer_details.email.should == "dan@example.com"
      transaction.customer_details.phone.should == "419-555-1234"
      transaction.customer_details.fax.should == "419-555-1235"
      transaction.customer_details.website.should == "http://braintreepaymentsolutions.com"
      transaction.billing_details.first_name.should == "Carl"
      transaction.billing_details.last_name.should == "Jones"
      transaction.billing_details.company.should == "Braintree"
      transaction.billing_details.street_address.should == "123 E Main St"
      transaction.billing_details.extended_address.should == "Suite 403"
      transaction.billing_details.locality.should == "Chicago"
      transaction.billing_details.region.should == "IL"
      transaction.billing_details.postal_code.should == "60622"
      transaction.billing_details.country_name.should == "United States of America"
      transaction.shipping_details.first_name.should == "Andrew"
      transaction.shipping_details.last_name.should == "Mason"
      transaction.shipping_details.company.should == "Braintree"
      transaction.shipping_details.street_address.should == "456 W Main St"
      transaction.shipping_details.extended_address.should == "Apt 2F"
      transaction.shipping_details.locality.should == "Bartlett"
      transaction.shipping_details.region.should == "IL"
      transaction.shipping_details.postal_code.should == "60103"
      transaction.shipping_details.country_name.should == "United States of America"
    end

    it "can store customer and credit card in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :store_in_vault => true
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should =~ /\A\d{6,7}\z/
      transaction.vault_customer.id.should == transaction.customer_details.id
      transaction.credit_card_details.token.should =~ /\A\w{4,5}\z/
      transaction.vault_credit_card.token.should == transaction.credit_card_details.token
    end

    it "associates a billing address with a credit card in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :first_name => "Carl",
          :last_name => "Jones",
          :company => "Braintree",
          :street_address => "123 E Main St",
          :extended_address => "Suite 403",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60622",
          :country_name => "United States of America"
        },
        :options => {
          :store_in_vault => true,
          :add_billing_address_to_payment_method => true,
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should =~ /\A\d{6,7}\z/
      transaction.vault_customer.id.should == transaction.customer_details.id
      credit_card = Braintree::CreditCard.find(transaction.vault_credit_card.token)
      transaction.billing_details.id.should == credit_card.billing_address.id
      transaction.vault_billing_address.id.should == credit_card.billing_address.id
      credit_card.billing_address.first_name.should == "Carl"
      credit_card.billing_address.last_name.should == "Jones"
      credit_card.billing_address.company.should == "Braintree"
      credit_card.billing_address.street_address.should == "123 E Main St"
      credit_card.billing_address.extended_address.should == "Suite 403"
      credit_card.billing_address.locality.should == "Chicago"
      credit_card.billing_address.region.should == "IL"
      credit_card.billing_address.postal_code.should == "60622"
      credit_card.billing_address.country_name.should == "United States of America"
    end

    it "can store the shipping address in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :shipping => {
          :first_name => "Carl",
          :last_name => "Jones",
          :company => "Braintree",
          :street_address => "123 E Main St",
          :extended_address => "Suite 403",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60622",
          :country_name => "United States of America"
        },
        :options => {
          :store_in_vault => true,
          :store_shipping_address_in_vault => true,
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should =~ /\A\d{6,7}\z/
      transaction.vault_customer.id.should == transaction.customer_details.id
      transaction.vault_shipping_address.id.should == transaction.vault_customer.addresses[0].id
      shipping_address = transaction.vault_customer.addresses[0]
      shipping_address.first_name.should == "Carl"
      shipping_address.last_name.should == "Jones"
      shipping_address.company.should == "Braintree"
      shipping_address.street_address.should == "123 E Main St"
      shipping_address.extended_address.should == "Suite 403"
      shipping_address.locality.should == "Chicago"
      shipping_address.region.should == "IL"
      shipping_address.postal_code.should == "60622"
      shipping_address.country_name.should == "United States of America"
    end

    it "submits for settlement if given transaction[options][submit_for_settlement]" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :submit_for_settlement => true
        }
      )
      result.success?.should == true
      result.transaction.status.should == "submitted_for_settlement"
    end

    it "can specify the customer id and payment method token" do
      customer_id = "customer_#{rand(1000000)}"
      payment_mehtod_token = "credit_card_#{rand(1000000)}"
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :id => customer_id,
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :token => payment_mehtod_token,
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :store_in_vault => true
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should == customer_id
      transaction.vault_customer.id.should == customer_id
      transaction.credit_card_details.token.should == payment_mehtod_token
      transaction.vault_credit_card.token.should == payment_mehtod_token
    end

    it "returns an error result if validations fail" do
      params = {
        :transaction => {
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      result.success?.should == false
      result.params.should == {:transaction => {:type => 'sale', :amount => nil, :credit_card => {:expiration_date => "05/2009"}}}
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
    end
  end

  describe "self.sale!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.id.should =~ /^\w{6}$/
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Transaction.sale!(
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.submit_for_settlement" do
    it "returns a successful result if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      result = Braintree::Transaction.submit_for_settlement(transaction.id)
      result.success?.should == true
    end

    it "can submit a specific amount for settlement" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = Braintree::Transaction.submit_for_settlement(transaction.id, "999.99")
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("999.99")
      result.transaction.status.should == "submitted_for_settlement"
      result.transaction.updated_at.between?(Time.now - 5, Time.now).should == true
    end

    it "returns an error result if settlement is too large" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = Braintree::Transaction.submit_for_settlement(transaction.id, "1000.01")
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge
      result.params[:transaction][:amount].should == "1000.01"
    end

    it "returns an error result if status is not authorized" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      result = Braintree::Transaction.submit_for_settlement(transaction.id)
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotSubmitForSettlement
    end
  end

  describe "self.submit_for_settlement!" do
    it "returns the transaction if successful" do
      original_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction = Braintree::Transaction.submit_for_settlement!(original_transaction.id)
      transaction.status.should == "submitted_for_settlement"
      transaction.id.should == original_transaction.id
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      expect do
        Braintree::Transaction.submit_for_settlement!(transaction.id, "1000.01")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.credit" do
    it "returns a successful result with type=credit if successful" do
      result = Braintree::Transaction.credit(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "credit"
      result.transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "returns an error result if validations fail" do
      params = {
        :transaction => {
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.credit(params[:transaction])
      result.success?.should == false
      result.params.should == {:transaction => {:type => 'credit', :amount => nil, :credit_card => {:expiration_date => "05/2009"}}}
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
    end
  end

  describe "self.credit!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.credit!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.id.should =~ /^\w{6}$/
      transaction.type.should == "credit"
      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Transaction.credit!(
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.create_from_transparent_redirect" do
    it "returns a successful result if successful" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      tr_data_params = {
        :transaction => {
          :type => "sale"
        }
      }
      query_string_response = create_transaction_via_tr(params, tr_data_params)
      result = Braintree::Transaction.create_from_transparent_redirect(query_string_response)
      result.success?.should == true
      transaction = result.transaction
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new("1000.00")
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "can put any param in tr_data" do
      params = {

      }
      tr_data_params = {
        :transaction => {
          :amount => "100.00",
          :order_id => "123",
          :type => "sale",
          :credit_card => {
            :number => "5105105105105100",
            :expiration_date => "05/2011",
            :cvv => "123"
          },
          :customer => {
            :first_name => "Dan",
            :last_name => "Smith",
            :company => "Braintree Payment Solutions",
            :email => "dan@example.com",
            :phone => "419-555-1234",
            :fax => "419-555-1235",
            :website => "http://braintreepaymentsolutions.com"
          },
          :billing => {
            :first_name => "Carl",
            :last_name => "Jones",
            :company => "Braintree",
            :street_address => "123 E Main St",
            :extended_address => "Suite 403",
            :locality => "Chicago",
            :region => "IL",
            :postal_code => "60622",
            :country_name => "United States of America"
          },
          :shipping => {
            :first_name => "Andrew",
            :last_name => "Mason",
            :company => "Braintree",
            :street_address => "456 W Main St",
            :extended_address => "Apt 2F",
            :locality => "Bartlett",
            :region => "IL",
            :postal_code => "60103",
            :country_name => "United States of America"
          }
        }
      }
      query_string_response = create_transaction_via_tr(params, tr_data_params)
      result = Braintree::Transaction.create_from_transparent_redirect(query_string_response)
      transaction = result.transaction
      transaction.id.should =~ /\A\w{6}\z/
      transaction.type.should == "sale"
      transaction.status.should == "authorized"
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.order_id.should == "123"
      transaction.processor_response_code.should == "1000"
      transaction.created_at.between?(Time.now - 60, Time.now).should == true
      transaction.updated_at.between?(Time.now - 60, Time.now).should == true
      transaction.credit_card_details.bin.should == "510510"
      transaction.credit_card_details.last_4.should == "5100"
      transaction.credit_card_details.masked_number.should == "510510******5100"
      transaction.credit_card_details.card_type.should == "MasterCard"
      transaction.avs_error_response_code.should == nil
      transaction.avs_postal_code_response_code.should == "M"
      transaction.avs_street_address_response_code.should == "M"
      transaction.cvv_response_code.should == "M"
      transaction.customer_details.first_name.should == "Dan"
      transaction.customer_details.last_name.should == "Smith"
      transaction.customer_details.company.should == "Braintree Payment Solutions"
      transaction.customer_details.email.should == "dan@example.com"
      transaction.customer_details.phone.should == "419-555-1234"
      transaction.customer_details.fax.should == "419-555-1235"
      transaction.customer_details.website.should == "http://braintreepaymentsolutions.com"
      transaction.billing_details.first_name.should == "Carl"
      transaction.billing_details.last_name.should == "Jones"
      transaction.billing_details.company.should == "Braintree"
      transaction.billing_details.street_address.should == "123 E Main St"
      transaction.billing_details.extended_address.should == "Suite 403"
      transaction.billing_details.locality.should == "Chicago"
      transaction.billing_details.region.should == "IL"
      transaction.billing_details.postal_code.should == "60622"
      transaction.billing_details.country_name.should == "United States of America"
      transaction.shipping_details.first_name.should == "Andrew"
      transaction.shipping_details.last_name.should == "Mason"
      transaction.shipping_details.company.should == "Braintree"
      transaction.shipping_details.street_address.should == "456 W Main St"
      transaction.shipping_details.extended_address.should == "Apt 2F"
      transaction.shipping_details.locality.should == "Bartlett"
      transaction.shipping_details.region.should == "IL"
      transaction.shipping_details.postal_code.should == "60103"
      transaction.shipping_details.country_name.should == "United States of America"
    end

    it "returns an error result if validations fail" do
      params = {
        :transaction => {
          :amount => "",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      tr_data_params = {
        :transaction => {
          :type => "sale"
        }
      }
      query_string_response = create_transaction_via_tr(params, tr_data_params)
      result = Braintree::Transaction.create_from_transparent_redirect(query_string_response)
      result.success?.should == false
      result.params[:transaction].should == {:amount => "", :type => "sale", :credit_card => {:expiration_date => "05/2009"}}
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
    end
  end

  describe "self.find" do
    it "finds the transaction with the given id" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      created_transaction = result.transaction
      found_transaction = Braintree::Transaction.find(created_transaction.id)
      found_transaction.should == created_transaction
    end

    it "raises a NotFoundError exception if transaction cannot be found" do
      expect do
        Braintree::Transaction.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'transaction with id "invalid-id" not found')
    end
  end

  describe "self.void" do
    it "returns a successful result if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result = Braintree::Transaction.void(transaction.id)
      result.success?.should == true
      result.transaction.id.should == transaction.id
      result.transaction.status.should == "voided"
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result = Braintree::Transaction.void(transaction.id)
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotBeVoided
    end
  end

  describe "self.void!" do
    it "returns the transaction if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      returned_transaction = Braintree::Transaction.void!(transaction.id)
      returned_transaction.should == transaction
      returned_transaction.status.should == "voided"
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      expect do
        Braintree::Transaction.void!(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "refund" do
    it "returns a successful result if successful" do
      transaction = create_transaction_to_refund
      transaction.status.should == "settled"
      result = transaction.refund
      result.success?.should == true
      result.new_transaction.type.should == "credit"
    end

    it "returns an error if already refunded" do
      transaction = create_transaction_to_refund
      result = transaction.refund
      result.success?.should == true
      result = transaction.refund
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::HasAlreadyBeenRefunded
    end

    it "returns an error result if unsettled" do
      transaction = Braintree::Transaction.create!(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result = transaction.refund
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotRefundUnlessSettled
    end
  end

  describe "submit_for_settlement" do
    it "returns a successful result if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      result = transaction.submit_for_settlement
      result.success?.should == true
    end

    it "can submit a specific amount for settlement" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = transaction.submit_for_settlement("999.99")
      result.success?.should == true
      transaction.amount.should == BigDecimal.new("999.99")
    end

    it "updates the transaction attributes" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = transaction.submit_for_settlement("999.99")
      result.success?.should == true
      transaction.amount.should == BigDecimal.new("999.99")
      transaction.status.should == "submitted_for_settlement"
      transaction.updated_at.between?(Time.now - 5, Time.now).should == true
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = transaction.submit_for_settlement("1000.01")
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge
      result.params[:transaction][:amount].should == "1000.01"
    end
  end

  describe "submit_for_settlement!" do
    it "returns the transaction if successful" do
      original_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction = original_transaction.submit_for_settlement!
      transaction.status.should == "submitted_for_settlement"
      transaction.id.should == original_transaction.id
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      expect do
        transaction.submit_for_settlement!("1000.01")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "search" do
    describe "advanced" do
      it "pretty much works in one big fell swoop/hash" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :order_id => "123",
          :customer => {
            :company => "Apple",
            :fax => "312-555-1234",
            :first_name => "Steve",
            :last_name => "Jobs",
            :phone => "614-555-1234",
            :website => "http://www.apple.com",
          },
          :billing => {
            :country_name => "United States of America",
            :extended_address => "Apt 1F",
            :locality => "Chicago",
            :postal_code => "60622",
            :region => "Illinois",
            :street_address => "1234 W North Ave",
          },
          :shipping => {
            :country_name => "United States of America",
            :extended_address => "Apt 123",
            :locality => "Bartlett",
            :postal_code => "60004",
            :region => "Illinois",
            :street_address => "123 Main St",
          }
        )
        result.success?.should == true
        expected_transaction = result.transaction
        search_criteria = {
          :billing_country_name => {:is => "United States of America"},
          :billing_extended_address => {:is => "Apt 1F"},
          :billing_locality => {:is => "Chicago"},
          :billing_postal_code => {:is => "60622"},
          :billing_region => {:is => "Illinois"},
          :billing_street_address => {:is => "1234 W North Ave"},
          :credit_card_number => {:is => Braintree::Test::CreditCardNumbers::Visa},
          :customer_company => {:is => "Apple"},
          :customer_fax => {:is => "312-555-1234"},
          :customer_first_name => {:is => "Steve"},
          :customer_last_name => {:is => "Jobs"},
          :customer_phone => {:is => "614-555-1234"},
          :customer_website => {:is => "http://www.apple.com"},
          :expiration_date => {:is => "05/2009"},
          :order_id => {:is => "123"},
          :shipping_country_name => {:is => "United States of America"},
          :shipping_extended_address => {:is => "Apt 123"},
          :shipping_locality => {:is => "Bartlett"},
          :shipping_postal_code => {:is => "60004"},
          :shipping_region => {:is => "Illinois"},
          :shipping_street_address => {:is => "123 Main St"},
        }
        search_results = Braintree::Transaction.search(search_criteria)
        search_results.should include(expected_transaction)
      end

      it "properly parses the xml if only one transaction is found" do
        transaction = Braintree::Transaction.create!(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
        search_results = Braintree::Transaction.search(:transaction_id => {:is => transaction.id})
        search_results.total_items.should == 1
        search_results[0].should == transaction
      end
    end

    describe "basic" do
      it "returns paged transactions matching the given search terms" do
        transactions = Braintree::Transaction.search "1111"
        transactions.total_items.should > 0
      end

      it "is paged" do
        transactions = Braintree::Transaction.search "1111", :page => 2
        transactions.current_page_number.should == 2
      end

      it "can traverse pages" do
        transactions = Braintree::Transaction.search "1111", :page => 1
        transactions.next_page.current_page_number.should == 2
      end
    end
  end

  describe "status_history" do
    it "returns an array of StatusDetail" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.submit_for_settlement!
      transaction.status_history.size.should == 2
      transaction.status_history[0].status.should == "authorized"
      transaction.status_history[1].status.should == "submitted_for_settlement"
    end
  end

  describe "vault_credit_card" do
    it "returns the Braintree::CreditCard if the transaction credit card is stored in the vault" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.credit_cards[0].sale(:amount => "100.00").transaction
      transaction.vault_credit_card.should == customer.credit_cards[0]
    end

    it "returns nil if the transaction credit card is not stored in the vault" do
      transaction = Braintree::Transaction.create!(
        :amount => "100.00",
        :type => "sale",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction.vault_credit_card.should == nil
    end
  end

  describe "vault_customer" do
    it "returns the Braintree::Customer if the transaction customer is stored in the vault" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.credit_cards[0].sale(:amount => "100.00").transaction
      transaction.vault_customer.should == customer
    end

    it "returns nil if the transaction customer is not stored in the vault" do
      transaction = Braintree::Transaction.create!(
        :amount => "100.00",
        :type => "sale",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction.vault_customer.should == nil
    end
  end

  describe "void" do
    it "returns a successful result if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.status.should == "authorized"
      void_result = transaction.void
      void_result.success?.should == true
      void_result.transaction.should == transaction
      transaction.status.should == void_result.transaction.status
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.status.should == "processor_declined"
      result = transaction.void
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotBeVoided
    end
  end

  describe "void!" do
    it "returns the transaction if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.void!.should == transaction
      transaction.status.should == "voided"
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.status.should == "processor_declined"
      expect do
        transaction.void!
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  def create_transaction_via_tr(params, tr_data_params)
    response = nil
    Net::HTTP.start(Braintree::Configuration.server, Braintree::Configuration.port) do |http|
      request = Net::HTTP::Post.new("/" + Braintree::Transaction.create_transaction_url.split("/", 4)[3])
      request.add_field "Content-Type", "application/x-www-form-urlencoded"
      params = {
        :tr_data => Braintree::TransparentRedirect.transaction_data({:redirect_url => "http://testing.com"}.merge(tr_data_params))
      }.merge(params)
      request.body = Braintree::Util.hash_to_query_string(params)
      response = http.request(request)
    end
    query_string = response["Location"].split("?", 2).last
    query_string
  end

  def create_transaction_to_refund
    transaction = Braintree::Transaction.sale!(
      :amount => Braintree::Test::TransactionAmounts::Authorize,
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009"
      },
      :options => {
        :submit_for_settlement => true
      }
    )

    response = Braintree::Http.put "/transactions/#{transaction.id}/settle"
    Braintree::Transaction.find(transaction.id)
  end
end
