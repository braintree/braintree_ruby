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
  end
end

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
