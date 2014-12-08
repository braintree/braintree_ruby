require "rubygems"
require "rspec/core/rake_task"

task :default => %w[spec:unit spec:integration]

task :dev_console do
  sh "irb -I lib -rubygems -r braintree -r env/development"
end

desc "Run units"
RSpec::Core::RakeTask.new("spec:unit") do |t|
  t.pattern = "spec/unit/**/*_spec.rb"
end

desc "Run integration"
RSpec::Core::RakeTask.new("spec:integration") do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

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
