$:.push File.expand_path("../lib", __FILE__)
require 'braintree/version'

Gem::Specification.new do |s|
  s.name = "braintree"
  s.summary = "Braintree Gateway Ruby Client Library"
  s.description = "Ruby library for integrating with the Braintree Gateway"
  s.version = Braintree::Version::String
  s.license = "MIT"
  s.author = "Braintree"
  s.email = "code@getbraintree.com"
  s.homepage = "https://www.braintreepayments.com/"
  # NEXT_MAJOR_VERSION remove this attribute as it is deprecated
  #                    https://blog.rubygems.org/2009/05/04/1.3.3-released.html
  s.has_rdoc = false  
  s.files = Dir.glob ["README.rdoc", "LICENSE", "lib/**/*.{rb,crt}", "spec/**/*", "*.gemspec"]
  s.add_dependency "builder", ">= 2.0.0"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/braintree/braintree_ruby/issues",
    "changelog_uri" => "https://github.com/braintree/braintree_ruby/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/braintree/braintree_ruby",
  }
end

