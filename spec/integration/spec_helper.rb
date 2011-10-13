unless defined?(INTEGRATION_SPEC_HELPER_LOADED)
  INTEGRATION_SPEC_HELPER_LOADED = true
  SSL_TEST_PORT = ENV['SSL_TEST_PORT'] || 8443

  require File.dirname(__FILE__) + "/../spec_helper"
  require File.dirname(__FILE__) + "/../hacks/tcp_socket"

  def start_ssl_server
    web_server_pid_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "httpsd.pid"))

    FileUtils.rm(web_server_pid_file) if File.exist?(web_server_pid_file)
    command = File.expand_path(File.join(File.dirname(__FILE__), "..", "script", "httpsd.rb"))
    `#{command} #{web_server_pid_file}`
    TCPSocket.wait_for_service :host => "127.0.0.1", :port => SSL_TEST_PORT

    yield

    10.times { unless File.exists?(web_server_pid_file); sleep 1; end }
  ensure
    Process.kill "INT", File.read(web_server_pid_file).to_i
  end

  def create_modification_for_tests(attributes)
    config = Braintree::Configuration.gateway.config
    config.http.post "/modifications/create_modification_for_tests", :modification => attributes
  end
end
