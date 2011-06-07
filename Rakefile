require "rubygems"
require "spec/rake/spectask"
require "rake/rdoctask"

task :default => %w[spec:unit spec:integration]

task :dev_console do
  sh "irb -I lib -rubygems -r braintree -r env/development"
end

desc "Run units"
Spec::Rake::SpecTask.new("spec:unit") do |t|
  t.spec_files = FileList["spec/unit/**/*_spec.rb"]
end

desc "Run integration"
Spec::Rake::SpecTask.new("spec:integration") do |t|
  t.spec_files = FileList["spec/integration/**/*_spec.rb"]
end

require File.dirname(__FILE__) + "/lib/braintree/version.rb"
gem_spec = Gem::Specification.new do |s|
  s.name = "braintree"
  s.summary = "Braintree Gateway Ruby Client Library"
  s.description = "Ruby library for integrating with the Braintree Gateway"
  s.version = Braintree::Version::String
  s.author = "Braintree"
  s.email = "code@getbraintree.com"
  s.homepage = "http://www.braintreepayments.com/"
  s.rubyforge_project = "braintree"
  s.has_rdoc = false
  s.files = FileList["README.rdoc", "LICENSE", "{lib,spec}/**/*.rb", "lib/**/*.crt"]
  s.add_dependency "builder", ">= 2.0.0"
end

task :gem do
  Gem::Builder.new(gem_spec).build
end

require File.dirname(__FILE__) + "/lib/braintree/configuration.rb"

desc 'Cleans generated files'
task :clean do
  rm_f Dir.glob('*.gem').join(" ")
  rm_rf "rdoc"
  rm_rf "bt_rdoc"
end
