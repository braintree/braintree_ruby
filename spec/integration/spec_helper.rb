require File.dirname(__FILE__) + "/../spec_helper"

require 'timeout'
require 'socket'


def start_ssl_server
  web_server_pid_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "httpsd.pid"))

  TCPSocket.class_eval do
    def self.wait_for_service(options)
      Timeout::timeout(options[:timeout] || 20) do
        loop do
          begin
            socket = TCPSocket.new(options[:host], options[:port])
            socket.close
            return
          rescue Errno::ECONNREFUSED
            sleep 0.5
          end
        end
      end
    end
  end

  FileUtils.rm(web_server_pid_file) if File.exist?(web_server_pid_file)
  command = File.expand_path(File.join(File.dirname(__FILE__), "..", "script", "httpsd.rb"))
  #puts command
  `#{command} #{web_server_pid_file}`
  #puts "== waiting for web server - port: #{8433}"
  TCPSocket.wait_for_service :host => "127.0.0.1", :port => 8443

  yield

  10.times { unless File.exists?(web_server_pid_file); sleep 1; end }
  #puts "\n== killing web server - pid: #{File.read(web_server_pid_file).to_i}"
  Process.kill "INT", File.read(web_server_pid_file).to_i
end
