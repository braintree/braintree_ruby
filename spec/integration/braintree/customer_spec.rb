require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Customer do
  describe "self.all" do
    it "returns page 1 if page isn't specified" do
      first_page = Braintree::Customer.all
      first_page.current_page_number.should == 1
    end

    it "can get the next_page" do
      first_page = Braintree::Customer.all
      first_page.current_page_number.should == 1
      second_page = first_page.next_page
      second_page.current_page_number.should == 2
    end
  end

  describe "self.delete" do
    it "deletes the customer with the given id" do
     create_result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      create_result.success?.should == true
      customer = create_result.customer

      delete_result = Braintree::Customer.delete(customer.id)
      delete_result.success?.should == true
      expect do
        Braintree::Customer.find(customer.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.create" do
    it "returns a successful result if successful" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :company => "Microsoft",
        :email => "bill@microsoft.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.microsoft.com"
      )
      result.success?.should == true
      result.customer.id.should =~ /^\d{6}$/
      result.customer.first_name.should == "Bill"
      result.customer.last_name.should == "Gates"
      result.customer.company.should == "Microsoft"
      result.customer.email.should == "bill@microsoft.com"
      result.customer.phone.should == "312.555.1234"
      result.customer.fax.should == "614.555.5678"
      result.customer.website.should == "www.microsoft.com"
      result.customer.created_at.between?(Time.now - 10, Time.now).should == true
      result.customer.updated_at.between?(Time.now - 10, Time.now).should == true
    end

    it "can create without any attributes" do
      result = Braintree::Customer.create
      result.success?.should == true
    end

    it "returns an error response if invalid" do
      result = Braintree::Customer.create(
        :email => "@invalid.com"
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
    end

    it "can create a customer and a payment method at the same time" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100"
        }
      )
      result.success?.should == true
      result.customer.first_name.should == "Mike"
      result.customer.last_name.should == "Jones"
      result.customer.credit_cards[0].bin.should == Braintree::Test::CreditCardNumbers::MasterCard[0, 6]
      result.customer.credit_cards[0].last_4.should == Braintree::Test::CreditCardNumbers::MasterCard[-4..-1]
      result.customer.credit_cards[0].expiration_date.should == "05/2010"
    end

    it "verifies the card if credit_card[options][verify_card]=true" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
          :expiration_date => "05/2010",
          :options => {:verify_card => true}
        }
      )
      result.success?.should == false
      result.credit_card_verification.status.should == "processor_declined"
    end

    it "can create a customer, payment method, and billing address at the same time" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :billing_address => {
            :street_address => "1 E Main St",
            :extended_address => "Suite 3",
            :locality => "Chicago",
            :region => "Illinois",
            :postal_code => "60622",
            :country_name => "United States of America"
          }
        }
      )
      result.success?.should == true
      result.customer.first_name.should == "Mike"
      result.customer.last_name.should == "Jones"
      result.customer.credit_cards[0].bin.should == Braintree::Test::CreditCardNumbers::MasterCard[0, 6]
      result.customer.credit_cards[0].last_4.should == Braintree::Test::CreditCardNumbers::MasterCard[-4..-1]
      result.customer.credit_cards[0].expiration_date.should == "05/2010"
      result.customer.credit_cards[0].billing_address.id.should == result.customer.addresses[0].id
      result.customer.addresses[0].id.should =~ /\w+/
      result.customer.addresses[0].street_address.should == "1 E Main St"
      result.customer.addresses[0].extended_address.should == "Suite 3"
      result.customer.addresses[0].locality.should == "Chicago"
      result.customer.addresses[0].region.should == "Illinois"
      result.customer.addresses[0].postal_code.should == "60622"
      result.customer.addresses[0].country_name.should == "United States of America"
    end

    it "stores custom fields when valid" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :custom_fields => {
          :store_me => "custom value"
        }
      )
      result.success?.should == true
      result.customer.custom_fields[:store_me].should == "custom value"
    end

    it "returns nested errors if credit card and/or billing address are invalid" do
      result = Braintree::Customer.create(
        :email => "invalid",
        :credit_card => {
          :number => "invalidnumber",
          :billing_address => {
            :country_name => "invalid"
          }
        }
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
      result.errors.for(:customer).for(:credit_card).on(:number)[0].message.should == "Credit card number is invalid."
      result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_name)[0].message.should == "Country name is not an accepted country."
    end

    it "returns errors if custom_fields are not registered" do
      result = Braintree::Customer.create(
        :first_name => "Jack",
        :last_name => "Kennedy",
        :custom_fields => {
          :spouse_name => "Jacqueline"
        }
      )
      result.success?.should == false
      result.errors.for(:customer).on(:custom_fields)[0].message.should == "Custom field is invalid: spouse_name."
    end
  end

  describe "self.create!" do
    it "returns the customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Jim",
        :last_name => "Smith"
      )
      customer.id.should =~ /\d+/
      customer.first_name.should == "Jim"
      customer.last_name.should == "Smith"
    end

    it "can create without any attributes" do
      customer = Braintree::Customer.create!
      customer.id.should =~ /\d+/
    end

    it "raises an exception if not successful" do
      expect do
        Braintree::Customer.create!(:email => "@foo.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.credit" do
    it "creates a credit transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = Braintree::Customer.credit(customer.id, :amount => "100.00")
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "credit"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.credit!" do
    it "creates a credit transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = Braintree::Customer.credit!(customer.id, :amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "credit"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.sale" do
    it "creates a sale transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = Braintree::Customer.sale(customer.id, :amount => "100.00")
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "sale"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.sale!" do
    it "creates a sale transaction for given customer id, returning the transaction" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = Braintree::Customer.sale!(customer.id, :amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "sale"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.transactions" do
    it "finds transactions for the given customer id" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.sale!(:amount => "100.00")
      collection = Braintree::Customer.transactions(customer.id)
      collection.current_page_number.should == 1
      collection.total_items.should == 1
      collection[0].should == transaction
    end
  end


  describe "sale" do
    it "creates a sale transaction using the customer, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = customer.sale(
        :amount => "100.00"
      )
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "sale"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "sale!" do
    it "returns the created sale tranaction if valid" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.sale!(:amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "sale"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "transactions" do
    it "finds transactions for the customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.sale!(:amount => "100.00")
      collection = customer.transactions
      collection.current_page_number.should == 1
      collection.total_items.should == 1
      collection[0].should == transaction
    end
  end

  describe "credit" do
    it "creates a credit transaction using the customer, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = customer.credit(
        :amount => "100.00"
      )
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "credit"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "credit!" do
    it "returns the created credit tranaction if valid" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.credit!(:amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "credit"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "create_from_transparent_redirect" do
    it "returns a successful result if successful" do
      params = {
        :customer => {
          :first_name => "John",
          :last_name => "Doe",
          :company => "Doe Co",
          :email => "john@doe.com",
          :phone => "312.555.2323",
          :fax => "614.555.5656",
          :website => "www.johndoe.com"
        }
      }
      query_string_response = create_customer_via_tr(params)
      result = Braintree::Customer.create_from_transparent_redirect(query_string_response)
      result.success?.should == true
      customer = result.customer
      customer.first_name.should == "John"
      customer.last_name.should == "Doe"
      customer.company.should == "Doe Co"
      customer.email.should == "john@doe.com"
      customer.phone.should == "312.555.2323"
      customer.fax.should == "614.555.5656"
      customer.website.should == "www.johndoe.com"
    end

    it "can pass any attribute through tr_data" do
      customer_id = "customer_#{rand(1_000_000)}"
      tr_data_params = {
        :customer => {
          :id => customer_id,
          :first_name => "John",
          :last_name => "Doe",
          :company => "Doe Co",
          :email => "john@doe.com",
          :phone => "312.555.2323",
          :fax => "614.555.5656",
          :website => "www.johndoe.com"
        }
      }
      query_string_response = create_customer_via_tr({}, tr_data_params)
      result = Braintree::Customer.create_from_transparent_redirect(query_string_response)
      result.success?.should == true
      customer = result.customer
      customer.id.should == customer_id
      customer.first_name.should == "John"
      customer.last_name.should == "Doe"
      customer.company.should == "Doe Co"
      customer.email.should == "john@doe.com"
      customer.phone.should == "312.555.2323"
      customer.fax.should == "614.555.5656"
      customer.website.should == "www.johndoe.com"
    end
  end

  describe "delete" do
    it "deletes the customer" do
     result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      result.success?.should == true

      customer = result.customer
      customer.delete.success?.should == true
      expect do
        Braintree::Customer.find(customer.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end


  describe "self.find" do
    it "finds the customer with the given id" do
      result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      result.success?.should == true

      customer = Braintree::Customer.find(result.customer.id)
      customer.id.should == result.customer.id
      customer.first_name.should == "Joe"
      customer.last_name.should == "Cool"
    end

    it "raises a NotFoundError exception if customer cannot be found" do
      expect do
        Braintree::Customer.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'customer with id "invalid-id" not found')
    end
  end

  describe "self.update" do
    it "updates the customer with the given id if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      result = Braintree::Customer.update(
        customer.id,
        :first_name => "Mr. Joe",
        :last_name => "Super Cool",
        :custom_fields => {
          :store_me => "a value"
        }
      )
      result.success?.should == true
      result.customer.id.should == customer.id
      result.customer.first_name.should == "Mr. Joe"
      result.customer.last_name.should == "Super Cool"
      result.customer.custom_fields[:store_me].should == "a value"
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(:email => "valid@email.com")
      result = Braintree::Customer.update(
        customer.id,
        :email => "@invalid.com"
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
    end
  end

  describe "self.update!" do
    it "returns the updated customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      updated_customer = Braintree::Customer.update!(
        customer.id,
        :first_name => "Mr. Joe",
        :last_name => "Super Cool"
      )
      updated_customer.first_name.should == "Mr. Joe"
      updated_customer.last_name.should == "Super Cool"
      updated_customer.updated_at.between?(Time.now - 5, Time.now).should == true
    end

    it "raises an error if unsuccessful" do
      customer = Braintree::Customer.create!(:email => "valid@email.com")
      expect do
        Braintree::Customer.update!(customer.id, :email => "@invalid.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "update" do
    it "updates the customer" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      update_result = customer.update(
        :first_name => "Mr. Joe",
        :last_name => "Super Cool"
      )
      update_result.success?.should == true
      update_result.customer.should == customer
      updated_customer = update_result.customer
      updated_customer.first_name.should == "Mr. Joe"
      updated_customer.last_name.should == "Super Cool"
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(
        :email => "valid@email.com"
      )
      result = customer.update(
        :email => "@invalid.com"
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
    end
  end

  describe "update!" do
    it "returns the customer and updates the customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      customer.update!(
        :first_name => "Mr. Joe",
        :last_name => "Super Cool"
      ).should == customer
      customer.first_name.should == "Mr. Joe"
      customer.last_name.should == "Super Cool"
      customer.updated_at.between?(Time.now - 5, Time.now).should == true
    end

    it "raises an error if unsuccessful" do
      customer = Braintree::Customer.create!(
        :email => "valid@email.com"
      )
      expect do
        customer.update!(:email => "@invalid.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "update_from_transparent_redirect" do
    it "returns a successful result if successful" do
      result = Braintree::Customer.create(
        :first_name => "Old First",
        :last_name => "Old Last",
        :company => "Old Company",
        :email => "old@email.com",
        :phone => "000.111.2222",
        :fax => "000.222.3333",
        :website => "old.website.com"
      )
      result.success?.should == true
      original_customer = result.customer
      params = {
        :customer => {
          :first_name => "New First",
          :last_name => "New Last",
          :company => "New Company",
          :email => "new@email.com",
          :phone => "888.111.2222",
          :fax => "999.222.3333",
          :website => "new.website.com"
        }
      }
      tr_data_params = {
        :customer_id => original_customer.id
      }
      query_string_response = update_customer_via_tr(params, tr_data_params)
      result = Braintree::Customer.update_from_transparent_redirect(query_string_response)
      result.success?.should == true
      customer = result.customer
      customer.id.should == original_customer.id
      customer.first_name.should == "New First"
      customer.last_name.should == "New Last"
      customer.company.should == "New Company"
      customer.email.should == "new@email.com"
      customer.phone.should == "888.111.2222"
      customer.fax.should == "999.222.3333"
      customer.website.should == "new.website.com"
    end

    it "can pass any attribute through tr_data" do
      original_customer = Braintree::Customer.create!(
        :first_name => "Old First",
        :last_name => "Old Last",
        :company => "Old Company",
        :email => "old@email.com",
        :phone => "000.111.2222",
        :fax => "000.222.3333",
        :website => "old.website.com"
      )
      new_customer_id = "customer_#{rand(1_000_000)}"
      tr_data_params = {
        :customer_id => original_customer.id,
        :customer => {
          :id => new_customer_id,
          :first_name => "New First",
          :last_name => "New Last",
          :company => "New Company",
          :email => "new@email.com",
          :phone => "888.111.2222",
          :fax => "999.222.3333",
          :website => "new.website.com"
        }
      }
      query_string_response = update_customer_via_tr({}, tr_data_params)
      result = Braintree::Customer.update_from_transparent_redirect(query_string_response)
      result.success?.should == true
      customer = result.customer
      customer.id.should == new_customer_id
      customer.first_name.should == "New First"
      customer.last_name.should == "New Last"
      customer.company.should == "New Company"
      customer.email.should == "new@email.com"
      customer.phone.should == "888.111.2222"
      customer.fax.should == "999.222.3333"
      customer.website.should == "new.website.com"
    end
  end

  def create_customer_via_tr(regular_params, tr_data_params = {})
    response = nil
    Net::HTTP.start(Braintree::Configuration.server, Braintree::Configuration.port) do |http|
      request = Net::HTTP::Post.new("/" + Braintree::Customer.create_customer_url.split("/", 4)[3])
      request.add_field "Content-Type", "application/x-www-form-urlencoded"
      params = {
        :tr_data => Braintree::TransparentRedirect.create_customer_data(
          {:redirect_url => "http://testing.com"}.merge(tr_data_params)
        )
      }.merge(regular_params)
      request.body = Braintree::Util.hash_to_query_string(params)
      response = http.request(request)
    end
    query_string = response["Location"].split("?", 2).last
    query_string
  end

  def update_customer_via_tr(regular_params, tr_data_params = {})
    raise "need a customer_id (of the customer to update) in tr_data_params" unless tr_data_params[:customer_id]
    response = nil
    Net::HTTP.start(Braintree::Configuration.server, Braintree::Configuration.port) do |http|
      request = Net::HTTP::Post.new("/" + Braintree::Customer.update_customer_url.split("/", 4)[3])
      request.add_field "Content-Type", "application/x-www-form-urlencoded"
      tr_data = Braintree::TransparentRedirect.update_customer_data(
        {:redirect_url => "http://testing.com"}.merge(tr_data_params)
      )
      request.body = Braintree::Util.hash_to_query_string({ :tr_data => tr_data }.merge(regular_params))
      response = http.request(request)
    end
    query_string = response["Location"].split("?", 2).last
  end
end
