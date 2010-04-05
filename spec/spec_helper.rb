unless defined?(SPEC_HELPER_LOADED)
  SPEC_HELPER_LOADED = true

  project_root = File.expand_path(File.dirname(__FILE__) + "/..")
  require "rubygems"
  gem "libxml-ruby", ENV["LIBXML_VERSION"] || "1.1.3"
  gem "builder", ENV["BUILDER_VERSION"] || "2.1.2"
  braintree_lib = "#{project_root}/lib"
  $LOAD_PATH << braintree_lib
  require "braintree"

  Braintree::Configuration.environment = :development
  Braintree::Configuration.merchant_id = "integration_merchant_id"
  Braintree::Configuration.public_key = "integration_public_key"
  Braintree::Configuration.private_key = "integration_private_key"
  Braintree::Configuration.logger = Logger.new("/dev/null")
  Braintree::Configuration.logger.level = Logger::INFO

  module SpecHelper
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

    def self.simulate_form_post_for_tr(url, tr_data_string, form_data_hash)
      response = nil
      Net::HTTP.start("localhost", Braintree::Configuration.port) do |http|
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
end

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
