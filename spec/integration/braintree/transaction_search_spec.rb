require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Transaction, "search" do
  context "advanced" do
    it "correctly returns a result with no matches" do
      collection = Braintree::Transaction.search do |search|
        search.billing_first_name.is "thisnameisnotreal"
      end

      collection._approximate_size.should == 0
    end

    it "returns one result for text field search" do
      first_name = "Tim#{rand(10000)}"
      token = "creditcard#{rand(10000)}"
      customer_id = "customer#{rand(10000)}"

      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
        :cardholder_name => "Tom Smith",
        :token => token,
      },
      :billing => {
        :company => "Braintree",
        :country_name => "United States of America",
        :extended_address => "Suite 123",
        :first_name => first_name,
        :last_name => "Smith",
        :locality => "Chicago",
        :postal_code => "12345",
        :region => "IL",
        :street_address => "123 Main St"
      },
      :customer => {
        :company => "Braintree",
        :email => "smith@example.com",
        :fax => "5551231234",
        :first_name => "Tom",
        :id => customer_id,
        :last_name => "Smith",
        :phone => "5551231234",
        :website => "http://example.com",
      },
      :options => {
        :store_in_vault => true
      },
        :order_id => "myorder",
        :shipping => {
        :company => "Braintree P.S.",
        :country_name => "Mexico",
        :extended_address => "Apt 456",
        :first_name => "Thomas",
        :last_name => "Smithy",
        :locality => "Braintree",
        :postal_code => "54321",
        :region => "MA",
        :street_address => "456 Road"
      }
      )

      search_criteria = {
        :billing_company => "Braintree",
        :billing_country_name => "United States of America",
        :billing_extended_address => "Suite 123",
        :billing_first_name => first_name,
        :billing_last_name => "Smith",
        :billing_locality => "Chicago",
        :billing_postal_code => "12345",
        :billing_region => "IL",
        :billing_street_address => "123 Main St",
        :credit_card_cardholder_name => "Tom Smith",
        :credit_card_expiration_date => "05/2012",
        :credit_card_number => Braintree::Test::CreditCardNumbers::Visa,
        :customer_company => "Braintree",
        :customer_email => "smith@example.com",
        :customer_fax => "5551231234",
        :customer_first_name => "Tom",
        :customer_id => customer_id,
        :customer_last_name => "Smith",
        :customer_phone => "5551231234",
        :customer_website => "http://example.com",
        :order_id => "myorder",
        :payment_method_token => token,
        :processor_authorization_code => transaction.processor_authorization_code,
        :shipping_company => "Braintree P.S.",
        :shipping_country_name => "Mexico",
        :shipping_extended_address => "Apt 456",
        :shipping_first_name => "Thomas",
        :shipping_last_name => "Smithy",
        :shipping_locality => "Braintree",
        :shipping_postal_code => "54321",
        :shipping_region => "MA",
        :shipping_street_address => "456 Road"
      }

      search_criteria.each do |criterion, value|
        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.send(criterion).is value
        end
        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.send(criterion).is("invalid_attribute")
        end
        collection.should be_empty
      end
    end

    it "searches all fields at once" do
      first_name = "Tim#{rand(10000)}"
      token = "creditcard#{rand(10000)}"
      customer_id = "customer#{rand(10000)}"

      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
        :cardholder_name => "Tom Smith",
        :token => token,
      },
      :billing => {
        :company => "Braintree",
        :country_name => "United States of America",
        :extended_address => "Suite 123",
        :first_name => first_name,
        :last_name => "Smith",
        :locality => "Chicago",
        :postal_code => "12345",
        :region => "IL",
        :street_address => "123 Main St"
      },
      :customer => {
        :company => "Braintree",
        :email => "smith@example.com",
        :fax => "5551231234",
        :first_name => "Tom",
        :id => customer_id,
        :last_name => "Smith",
        :phone => "5551231234",
        :website => "http://example.com",
      },
      :options => {
        :store_in_vault => true
      },
      :order_id => "myorder",
      :shipping => {
        :company => "Braintree P.S.",
        :country_name => "Mexico",
        :extended_address => "Apt 456",
        :first_name => "Thomas",
        :last_name => "Smithy",
        :locality => "Braintree",
        :postal_code => "54321",
        :region => "MA",
        :street_address => "456 Road"
      })

      collection = Braintree::Transaction.search do |search|
        search.billing_company.is "Braintree"
        search.billing_country_name.is "United States of America"
        search.billing_extended_address.is "Suite 123"
        search.billing_first_name.is first_name
        search.billing_last_name.is "Smith"
        search.billing_locality.is "Chicago"
        search.billing_postal_code.is "12345"
        search.billing_region.is "IL"
        search.billing_street_address.is "123 Main St"
        search.credit_card_cardholder_name.is "Tom Smith"
        search.credit_card_expiration_date.is "05/2012"
        search.credit_card_number.is Braintree::Test::CreditCardNumbers::Visa
        search.customer_company.is "Braintree"
        search.customer_email.is "smith@example.com"
        search.customer_fax.is "5551231234"
        search.customer_first_name.is "Tom"
        search.customer_id.is customer_id
        search.customer_last_name.is "Smith"
        search.customer_phone.is "5551231234"
        search.customer_website.is "http://example.com"
        search.order_id.is "myorder"
        search.payment_method_token.is token
        search.processor_authorization_code.is transaction.processor_authorization_code
        search.shipping_company.is "Braintree P.S."
        search.shipping_country_name.is "Mexico"
        search.shipping_extended_address.is "Apt 456"
        search.shipping_first_name.is "Thomas"
        search.shipping_last_name.is "Smithy"
        search.shipping_locality.is "Braintree"
        search.shipping_postal_code.is "54321"
        search.shipping_region.is "MA"
        search.shipping_street_address.is "456 Road"
        search.id.is transaction.id
      end

      collection._approximate_size.should == 1
      collection.first.id.should == transaction.id
    end

    context "multiple value fields" do
      it "searches on created_using" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_using.is Braintree::Transaction::CreatedUsing::FullInformation
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_using.in Braintree::Transaction::CreatedUsing::FullInformation, Braintree::Transaction::CreatedUsing::Token
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_using.is Braintree::Transaction::CreatedUsing::Token
        end

        collection._approximate_size.should == 0
      end

      it "searches on credit_card_customer_location" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_customer_location.is Braintree::CreditCard::CustomerLocation::US
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_customer_location.in Braintree::CreditCard::CustomerLocation::US, Braintree::CreditCard::CustomerLocation::International
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_customer_location.is Braintree::CreditCard::CustomerLocation::International
        end

        collection._approximate_size.should == 0
      end

      it "searches on merchant_account_id" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.merchant_account_id.is transaction.merchant_account_id
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.merchant_account_id.in transaction.merchant_account_id, "bogus_merchant_account_id"
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.merchant_account_id.is "bogus_merchant_account_id"
        end

        collection._approximate_size.should == 0
      end

      it "searches on credit_card_card_type" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is Braintree::CreditCard::CardType::Visa
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is transaction.credit_card_details.card_type
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.in Braintree::CreditCard::CardType::Visa, Braintree::CreditCard::CardType::MasterCard
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is Braintree::CreditCard::CardType::MasterCard
        end

        collection._approximate_size.should == 0
      end

      it "searches on status" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.status.is Braintree::Transaction::Status::Authorized
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.status.in Braintree::Transaction::Status::Authorized, Braintree::Transaction::Status::ProcessorDeclined
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.status.is Braintree::Transaction::Status::ProcessorDeclined
        end

        collection._approximate_size.should == 0
      end

      it "searches on source" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          }
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.source.is Braintree::Transaction::Source::Api
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.source.in Braintree::Transaction::Source::Api, Braintree::Transaction::Source::ControlPanel
        end

        collection._approximate_size.should == 1

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.source.is Braintree::Transaction::Source::ControlPanel
        end

        collection._approximate_size.should == 0
      end

      it "searches on type" do
        cardholder_name = "refunds#{rand(10000)}"
        credit_transaction = Braintree::Transaction.credit!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :cardholder_name => cardholder_name,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :cardholder_name => cardholder_name,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        :options => { :submit_for_settlement => true }
        )
        Braintree::Http.put "/transactions/#{transaction.id}/settle"

        refund_transaction = transaction.refund.new_transaction

        collection = Braintree::Transaction.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
          search.type.is Braintree::Transaction::Type::Credit
        end

        collection._approximate_size.should == 2

        collection = Braintree::Transaction.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
          search.type.is Braintree::Transaction::Type::Credit
          search.refund.is true
        end

        collection._approximate_size.should == 1
        collection.first.id.should == refund_transaction.id

        collection = Braintree::Transaction.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
          search.type.is Braintree::Transaction::Type::Credit
          search.refund.is false
        end

        collection._approximate_size.should == 1
        collection.first.id.should == credit_transaction.id
      end
    end

    context "range fields" do
      context "amount" do
        it "searches on amount" do
          transaction = Braintree::Transaction.sale!(
            :amount => "1000.00",
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          }
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount.between "500.00", "1500.00"
          end

          collection._approximate_size.should == 1
          collection.first.id.should == transaction.id

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount >= "500.00"
          end

          collection._approximate_size.should == 1
          collection.first.id.should == transaction.id

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount <= "1500.00"
          end

          collection._approximate_size.should == 1
          collection.first.id.should == transaction.id

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount.between "500.00", "900.00"
          end

          collection._approximate_size.should == 0
        end

        it "can also take BigDecimal for amount" do
          transaction = Braintree::Transaction.sale!(
            :amount => BigDecimal.new("1000.00"),
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          }
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount <= BigDecimal.new("1000.00")
          end

          collection._approximate_size.should == 1
        end
      end

      it "searches on created_at in UTC" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        created_at = transaction.created_at
        created_at.should be_utc

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at.between(
            created_at - 60,
            created_at + 60
          )
        end

        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at >= created_at - 1
        end

        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at <= created_at + 1
        end

        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at.between(
            created_at - 300,
            created_at - 100
          )
        end

        collection._approximate_size.should == 0
      end

      it "searches on created_at in local time" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        }
        )

        now = Time.now

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at.between(
            now - 60,
            now + 60
          )
        end

        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at >= now - 60
        end

        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at <= now + 60
        end

        collection._approximate_size.should == 1
        collection.first.id.should == transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_at.between(
            now - 300,
            now - 100
          )
        end

        collection._approximate_size.should == 0
      end
    end

    it "returns multiple results" do
      collection = Braintree::Transaction.search
      collection._approximate_size.should > 100

      transaction_ids = collection.map {|t| t.id }.uniq.compact
      transaction_ids.size.should == collection._approximate_size
    end

    context "text node operations" do
      before(:each) do
        @transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :cardholder_name => "Tom Smith"
          }
        )
      end

      it "is" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is "Tom Smith"
        end

        collection._approximate_size.should == 1
        collection.first.id.should == @transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is "Invalid"
        end

        collection._approximate_size.should == 0
      end

      it "is_not" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is_not "Anybody Else"
        end

        collection._approximate_size.should == 1
        collection.first.id.should == @transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is_not "Tom Smith"
        end

        collection._approximate_size.should == 0
      end

      it "ends_with" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.ends_with "m Smith"
        end

        collection._approximate_size.should == 1
        collection.first.id.should == @transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.ends_with "Tom S"
        end

        collection._approximate_size.should == 0
      end

      it "starts_with" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.starts_with "Tom S"
        end

        collection._approximate_size.should == 1
        collection.first.id.should == @transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.starts_with "m Smith"
        end

        collection._approximate_size.should == 0
      end

      it "contains" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.contains "m Sm"
        end

        collection._approximate_size.should == 1
        collection.first.id.should == @transaction.id

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.contains "Anybody Else"
        end

        collection._approximate_size.should == 0
      end
    end
  end
end
