unless defined?(INTEGRATION_SPEC_HELPER_LOADED)
  INTEGRATION_SPEC_HELPER_LOADED = true

  require File.dirname(__FILE__) + "/../spec_helper"
  require File.dirname(__FILE__) + "/../hacks/tcp_socket"

  Spec::Runner.configure do |config|
    CLIENT_LIB_ROOT = File.expand_path(File.dirname(__FILE__) + "/../..")
    GATEWAY_ROOT = File.expand_path("#{CLIENT_LIB_ROOT}/../gateway")
    GATEWAY_SERVER_PORT = 3000
    GATEWAY_PID_FILE = "/tmp/gateway_server_#{Braintree::Configuration.port}.pid"
    SPHINX_PID_FILE = "#{GATEWAY_ROOT}/log/searchd.integration.pid"
    
    gateway_already_started = File.exist?(GATEWAY_PID_FILE)
    sphinx_already_started = File.exist?(SPHINX_PID_FILE)
    config.before(:suite) do
       Dir.chdir(CLIENT_LIB_ROOT) do
        system "rake start_gateway" or raise "rake start_gateway failed" unless gateway_already_started
        system "rake start_sphinx" or raise "rake start_sphinx failed" unless sphinx_already_started
      end
    end

    config.after(:suite) do
      Dir.chdir(CLIENT_LIB_ROOT) do
        system "rake stop_gateway" or raise "rake stop_gateway failed" unless gateway_already_started
        system "rake stop_sphinx" or raise "rake stop_sphinx failed" unless sphinx_already_started
      end
    end
  end

  def start_ssl_server
    web_server_pid_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "httpsd.pid"))

    FileUtils.rm(web_server_pid_file) if File.exist?(web_server_pid_file)
    command = File.expand_path(File.join(File.dirname(__FILE__), "..", "script", "httpsd.rb"))
    `#{command} #{web_server_pid_file}`
    TCPSocket.wait_for_service :host => "127.0.0.1", :port => 8443

    yield

    10.times { unless File.exists?(web_server_pid_file); sleep 1; end }
    Process.kill "INT", File.read(web_server_pid_file).to_i
  end
end
