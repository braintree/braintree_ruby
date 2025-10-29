$:.push File.expand_path("../lib", __FILE__)
require "braintree/version"

Gem::Specification.new do |s|
  s.name = "braintree"
  s.summary = "Braintree Ruby Server SDK"
  s.description = "Resources and tools for developers to integrate Braintree's global payments platform."
  s.version = Braintree::Version::String
  s.license = "MIT"
  s.author = "Braintree"
  s.email = "code@getbraintree.com"
  s.homepage = "https://www.braintreepayments.com/"
  s.files = Dir.glob ["README.rdoc", "LICENSE", "lib/**/*.{rb,crt}", "spec/**/*", "*.gemspec"]
  s.add_dependency "builder", ">= 3.2.4"
  s.add_dependency "rexml", ">= 3.1.9" # Use rexml version associated with minimum supported Ruby version
  s.add_dependency "base64", ">= 0.3.0"
  s.add_dependency "bigdecimal", ">= 3.3.1"
  s.add_dependency "logger", ">= 1.7.0"
  s.add_dependency "ostruct", ">= 0.6.3"
  s.required_ruby_version = ">=2.6.0"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/braintree/braintree_ruby/issues",
    "changelog_uri" => "https://github.com/braintree/braintree_ruby/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/braintree/braintree_ruby",
    "documentation_uri" => "https://developer.paypal.com/braintree/docs"
  }
end

