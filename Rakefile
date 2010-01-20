require "rubygems"
require "spec/rake/spectask"
require "rake/rdoctask"

task :default => %w[spec:unit spec:integration]

task :dev_console do
  sh "irb -I lib -rubygems -r braintree -r env/development"
end

task :qa_console do
  sh "irb -I lib -rubygems -r braintree -r env/qa"
end

desc "Run units"
Spec::Rake::SpecTask.new("spec:unit") do |t|
  t.spec_files = FileList["spec/unit/**/*_spec.rb"]
end

desc "Run integration"
Spec::Rake::SpecTask.new("spec:integration") do |t|
  t.spec_files = FileList["spec/integration/**/*_spec.rb"]
end

desc "run integration keeping the gateway server and sphinx running"
task "start_servers_and_run_integration_specs" => [:start_gateway, :start_sphinx, "spec:integration", :stop_gateway, :stop_sphinx]

desc "run integration tests after preping the gateway (including git clone and db reset), what the build needs to run"
task "run_integration_specs_for_cruise" => [:prep_gateway, "spec:integration", :stop_gateway, :stop_sphinx]

def configure_rdoc_task(t)
  t.main = "README.rdoc"
  t.rdoc_files.include("README.rdoc", "LICENSE", "lib/**/*.rb")
  t.title = "Braintree Ruby Documentation"
end

Rake::RDocTask.new do |t|
  configure_rdoc_task(t)
  t.rdoc_dir = "rdoc"
end

Rake::RDocTask.new(:bt_rdoc) do |t|
  configure_rdoc_task(t)
  t.rdoc_dir = "bt_rdoc"
  t.template = "bt_rdoc_template/braintree"
end

task :bt_rdoc_postprocessing do
  FileUtils.cp "bt_rdoc_template/braintree.gif", "bt_rdoc"
  FileUtils.cp "bt_rdoc_template/ruby.png", "bt_rdoc"
  Dir.glob("bt_rdoc/**/*.html") do |html_file|
    original = File.read(html_file)
    next unless original =~ /STYLE_URL/
    base_url = original[/STYLE_URL = (.*)\/.*/, 1]
    updated = original.gsub("BASE_URL", base_url)
    File.open(html_file, "w") { |f| f.write updated }
  end
end
task(:bt_rdoc) { Rake::Task["bt_rdoc_postprocessing"].invoke }

require File.dirname(__FILE__) + "/lib/braintree/version.rb"
gem_spec = Gem::Specification.new do |s|
  s.name = "braintree"
  s.summary = "Braintree Gateway Ruby Client Library"
  s.description = "Ruby library for integrating with the Braintree Gateway"
  s.version = Braintree::Version::String
  s.author = "Braintree Payment Solutions"
  s.email = "devs@getbraintree.com"
  s.homepage = "http://www.braintreepaymentsolutions.com/gateway"
  s.rubyforge_project = "braintree"
  s.has_rdoc = false
  s.files = FileList["README.rdoc", "LICENSE", "{lib,spec}/**/*.rb", "lib/**/*.crt"]
end

task :gem do
  Gem::Builder.new(gem_spec).build
end

require File.dirname(__FILE__) + "/lib/braintree/configuration.rb"

CRUISE_BUILD = "CRUISE_BUILD=#{ENV['CRUISE_BUILD']}"
GATEWAY_ROOT = File.dirname(__FILE__) + "/../gateway" unless defined?(GATEWAY_ROOT)
Braintree::Configuration.environment = :development
PID_FILE = "/tmp/gateway_server_#{Braintree::Configuration.port}.pid"

task :prep_gateway do
  Dir.chdir(GATEWAY_ROOT) do
    sh "git pull"
    sh "env RAILS_ENV=integration #{CRUISE_BUILD} SPHINX_PORT=#{ENV['SPHINX_PORT']} rake db:migrate:reset --trace"
    sh "env RAILS_ENV=integration #{CRUISE_BUILD} SPHINX_PORT=#{ENV['SPHINX_PORT']} ruby script/populate_data"
    Rake::Task[:start_gateway].invoke
    Rake::Task[:start_sphinx].invoke
  end
end

task :start_gateway do
  Dir.chdir(GATEWAY_ROOT) do
    spawn_server(PID_FILE, Braintree::Configuration.port, "integration")
  end
end

task :start_sphinx do
  Dir.chdir(GATEWAY_ROOT) do
    sh "env RAILS_ENV=integration #{CRUISE_BUILD} SPHINX_PORT=#{ENV['SPHINX_PORT']} rake ts:rebuild --trace"
  end  
end

task :stop_gateway do
  Dir.chdir(GATEWAY_ROOT) do
    shutdown_server(PID_FILE)
  end
end

task :stop_sphinx do
  Dir.chdir(GATEWAY_ROOT) do
    sh "env RAILS_ENV=integration rake ts:stop --trace"
  end
end

def spawn_server(pid_file, port, environment="test")
  require File.dirname(__FILE__) + "/spec/hacks/tcp_socket"

  FileUtils.rm(pid_file) if File.exist?(pid_file)
  command = "mongrel_rails start --environment #{environment} --daemon --port #{port} --pid #{pid_file}"

  sh command
  puts "== waiting for web server - port: #{port}"
  TCPSocket.wait_for_service :host => "127.0.0.1", :port => port
end

def shutdown_server(pid_file)
  10.times { unless File.exists?(pid_file); sleep 1; end }
  puts "\n== killing web server - pid: #{File.read(pid_file).to_i}"
  Process.kill "TERM", File.read(pid_file).to_i
end
