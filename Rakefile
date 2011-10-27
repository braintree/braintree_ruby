require "rubygems"
require "spec/rake/spectask"
require "rake/rdoctask"

task :default => %w[spec:unit spec:integration]

desc "Development console"
task :dev_console do
  sh "irb -I . -I lib -rubygems -r braintree -r env/development"
end

desc "Run units"
Spec::Rake::SpecTask.new("spec:unit") do |t|
  t.spec_files = FileList["spec/unit/**/*_spec.rb"]
end

desc "Run integration"
Spec::Rake::SpecTask.new("spec:integration") do |t|
  t.spec_files = FileList["spec/integration/**/*_spec.rb"]
end

desc "Build gem from gemspec"
task :gem do
  gemspec = eval(File.read('braintree.gemspec'))
  Gem::Builder.new(gemspec).build
end

desc 'Cleans generated files'
task :clean do
  rm_f Dir.glob('*.gem').join(" ")
  rm_rf "rdoc"
  rm_rf "bt_rdoc"
end
