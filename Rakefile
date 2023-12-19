require "rubygems"
require "rspec/core/rake_task"

task :default => "test:all"

task :dev_console do
  sh "irb -I lib -rubygems -r braintree -r env/development"
end

task :lint do
  puts "Running rubocop for linting, you can autocorrect by running `rubocop -a`"
  sh "rubocop"
end

namespace :test do

  # Usage:
  #   rake test:unit
  #   rake test:unit[configuration_spec]
  #   rake test:unit[configuration_spec,"accepts merchant credentials"]
  desc "Run unit tests"
  task :unit, [:file_name, :test_name] => [:lint] do |_task, args|
    if args.file_name.nil?
      sh "rspec --pattern spec/unit/**/*_spec.rb"
    elsif args.test_name.nil?
      sh "rspec --pattern spec/unit/**/#{args.file_name}.rb --format documentation --color"
    else
      sh "rspec --pattern spec/unit/**/#{args.file_name}.rb --example '#{args.test_name}' --format documentation --color"
    end
  end

  # Usage:
  #   rake test:integration
  #   rake test:integration[plan_spec]
  #   rake test:integration[plan_spec,"gets all plans"]
  desc "Run integration tests"
  task :integration, [:file_name, :test_name] => [:lint] do |_task, args|
    if args.file_name.nil?
      sh "rspec --pattern spec/integration/**/*_spec.rb"
    elsif args.test_name.nil?
      sh "rspec --pattern spec/integration/**/#{args.file_name}.rb --format documentation --color"
    else
      sh "rspec --pattern spec/integration/**/#{args.file_name}.rb --example '#{args.test_name}' --format documentation --color"
    end
  end

  task :all => [:unit, :integration]
end

task :test => "test:all"

task :gem do
  exec("gem build braintree.gemspec")
end

require File.dirname(__FILE__) + "/lib/braintree/configuration.rb"

desc "Cleans generated files"
task :clean do
  rm_f Dir.glob("*.gem").join(" ")
  rm_rf "rdoc"
  rm_rf "bt_rdoc"
end
