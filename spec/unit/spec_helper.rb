if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov_json_formatter"
  SimpleCov.start do
    add_filter "/spec/"
    formatter SimpleCov::Formatter::JSONFormatter
  end
end

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
