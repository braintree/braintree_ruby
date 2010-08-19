unless defined?(SPEC_HELPER_LOADED)
  SPEC_HELPER_LOADED = true

  project_root = File.expand_path(File.dirname(__FILE__) + "/..")
  require "rubygems"
  gem "libxml-ruby", ENV["LIBXML_VERSION"] || "1.1.3"
  require "libxml"
  gem "builder", ENV["BUILDER_VERSION"] || "2.1.2"
  braintree_lib = "#{project_root}/lib"
  $LOAD_PATH << braintree_lib
  require "braintree"

  Braintree::Configuration.environment = :development
  Braintree::Configuration.merchant_id = "integration_merchant_id"
  Braintree::Configuration.public_key = "integration_public_key"
  Braintree::Configuration.private_key = "integration_private_key"
  logger = Logger.new("/dev/null")
  logger.level = Logger::INFO
  Braintree::Configuration.logger = logger

  module Kernel
    alias_method :original_warn, :warn
    def warn(message)
      return if message =~ /^\[DEPRECATED\]/
      original_warn(message)
    end
  end

  module SpecHelper

    DefaultMerchantAccountId = "sandbox_credit_card"
    NonDefaultMerchantAccountId = "sandbox_credit_card_non_default"

    TrialPlan = {
      :description => "Plan for integration tests -- with trial",
      :id => "integration_trial_plan",
      :price => BigDecimal.new("43.21"),
      :trial_period => true,
      :trial_duration => 2,
      :trial_duration_unit => Braintree::Subscription::TrialDurationUnit::Day
    }

    TriallessPlan = {
      :description => "Plan for integration tests -- without a trial",
      :id => "integration_trialless_plan",
      :price => BigDecimal.new("12.34"),
      :trial_period => false
    }

    AddOnDiscountPlan = {
      :description => "Plan for integration tests -- with add-ons and discounts",
      :id => "integration_plan_with_add_ons_and_discounts",
      :price => BigDecimal.new("9.99"),
      :trial_period => true,
      :trial_duration => 2,
      :trial_duration_unit => Braintree::Subscription::TrialDurationUnit::Day
    }

    BillingDayOfMonthPlan = {
      :description => "Plan for integration tests -- with billing day of month",
      :id => "integration_plan_with_billing_day_of_month",
      :price => BigDecimal.new("8.88"),
      :billing_day_of_month => 5
    }

    AddOnIncrease10 = "increase_10"
    AddOnIncrease20 = "increase_20"
    AddOnIncrease30 = "increase_30"

    Discount7 = "discount_7"
    Discount11 = "discount_11"
    Discount15 = "discount_15"

    def self.make_past_due(subscription, number_of_days_past_due = 1)
      Braintree::Configuration.instantiate.http.put(
        "/subscriptions/#{subscription.id}/make_past_due?days_past_due=#{number_of_days_past_due}"
      )
    end

    def self.settle_transaction(transaction_id)
      Braintree::Configuration.instantiate.http.put("/transactions/#{transaction_id}/settle")
    end

    def self.stub_time_dot_now(desired_time)
      Time.class_eval do
        class << self
          alias original_now now
        end
      end
      (class << Time; self; end).class_eval do
        define_method(:now) { desired_time }
      end
      yield
    ensure
      Time.class_eval do
        class << self
          alias now original_now
        end
      end
    end

    def self.simulate_form_post_for_tr(tr_data_string, form_data_hash, url = Braintree::TransparentRedirect.url)
      response = nil
      Net::HTTP.start("localhost", Braintree::Configuration.instantiate.port) do |http|
        request = Net::HTTP::Post.new("/" + url.split("/", 4)[3])
        request.add_field "Content-Type", "application/x-www-form-urlencoded"
        request.body = Braintree::Util.hash_to_query_string({:tr_data => tr_data_string}.merge(form_data_hash))
        response = http.request(request)
      end
      if response.code.to_i == 303
        response["Location"].split("?", 2).last
      else
        raise "did not receive a valid tr response: #{response.body[0,1000].inspect}"
      end
    end

    def self.using_configuration(config = {}, &block)
      original_values = {}
      [:merchant_id, :public_key, :private_key].each do |key|
        if config[key]
          original_values[key] = Braintree::Configuration.send(key)
          Braintree::Configuration.send("#{key}=", config[key])
        end
      end
      begin
        yield
      ensure
        original_values.each do |key, value|
          Braintree::Configuration.send("#{key}=", value)
        end
      end
    end
  end

  module CustomMatchers
    class ParseTo
      def initialize(hash)
        @expected_hash = hash
      end

      def matches?(xml_string)
        @libxml_parse = Braintree::Xml::Parser.hash_from_xml(xml_string, Braintree::Xml::Libxml)
        @rexml_parse = Braintree::Xml::Parser.hash_from_xml(xml_string, Braintree::Xml::Rexml)
        if @libxml_parse != @expected_hash
          @results = @libxml_parse
          @failed_parser = "libxml"
          false
        elsif @rexml_parse != @expected_hash
          @results = @rexml_parse
          @failed_parser = "rexml"
          false
        else
          true
        end
      end

      def failure_message
        "xml parsing failed for #{@failed_parser}, expected #{@expected_hash.inspect} but was #{@results.inspect}"
      end

      def negative_failure_message
        raise NotImplementedError
      end
    end

    def parse_to(hash)
      ParseTo.new(hash)
    end
  end

  Spec::Runner.configure do |config|
    config.include CustomMatchers
  end
end

