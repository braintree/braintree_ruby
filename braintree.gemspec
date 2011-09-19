Gem::Specification.new do |s|
  s.name = "braintree"
  s.summary = "Braintree Gateway Ruby Client Library"
  s.description = "Ruby library for integrating with the Braintree Gateway"
  s.version = '2.11.0'
  s.author = "Braintree"
  s.email = "code@getbraintree.com"
  s.homepage = "http://www.braintreepayments.com/"
  s.rubyforge_project = "braintree"
  s.has_rdoc = false
  s.files = Dir["README.rdoc", "LICENSE", "{lib,spec}/**/*.rb", "lib/**/*.crt"]

  s.add_dependency "builder", ">= 2.0.0"
  s.add_dependency "libxml-ruby", ">= 1.1.3"

  s.add_development_dependency "rspec", "~> 1.2.9"
end
