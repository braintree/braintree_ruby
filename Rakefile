require "rubygems"
require "rspec/core/rake_task"

task :default => "test:all"

task :dev_console do
  sh "irb -I lib -rubygems -r braintree -r env/development"
end

namespace :test do
  desc "Run unit tests"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/unit/**/*_spec.rb"
  end

  desc "Run integration tests"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = "spec/integration/**/*_spec.rb"
  end

  task :all => [:unit, :integration]
end

task :test => "test:all"

task :gem do
  exec('gem build braintree.gemspec')
end

require File.dirname(__FILE__) + "/lib/braintree/configuration.rb"

desc 'Cleans generated files'
task :clean do
  rm_f Dir.glob('*.gem').join(" ")
  rm_rf "rdoc"
  rm_rf "bt_rdoc"
end
