# frozen_string_literal: true

require 'socket'
require 'timeout'

module Bsh
  class PortScanner
    def self.scan(host, ports)
      puts "Port Scanner"
      puts "=" * 60
      puts
      puts "Note: This tool only scans for open ports. It does not attempt"
      puts "to exploit or gain unauthorized access to any services."
      puts
      puts "Scanning host: #{host}"
      puts "Ports to scan: #{ports.join(', ')}"
      puts

      open_ports = []
      closed_ports = []

      ports.each do |port|
        status = check_port(host, port)
        if status[:open]
          open_ports << port
          puts "  Port #{port}: OPEN (#{status[:service] || 'Unknown service'})"
        else
          closed_ports << port
          puts "  Port #{port}: CLOSED"
        end
      end

      puts
      puts "Summary:"
      puts "  Open ports: #{open_ports.length} (#{open_ports.join(', ')})"
      puts "  Closed ports: #{closed_ports.length}"
      puts
    end

    def self.check_port(host, port, timeout: 2)
      begin
        Timeout.timeout(timeout) do
          socket = Socket.tcp(host, port, connect_timeout: timeout)
          socket.close
          
          service = get_service_name(port)
          { open: true, service: service }
        end
      rescue Errno::ECONNREFUSED
        { open: false }
      rescue Errno::ETIMEDOUT, Timeout::Error
        { open: false }
      rescue StandardError => e
        { open: false }
      end
    end

    def self.get_service_name(port)
      common_ports = {
        20 => 'FTP Data',
        21 => 'FTP',
        22 => 'SSH',
        23 => 'Telnet',
        25 => 'SMTP',
        53 => 'DNS',
        80 => 'HTTP',
        110 => 'POP3',
        143 => 'IMAP',
        443 => 'HTTPS',
        465 => 'SMTPS',
        587 => 'SMTP Submission',
        993 => 'IMAPS',
        995 => 'POP3S',
        1433 => 'MSSQL',
        3306 => 'MySQL',
        3389 => 'RDP',
        5432 => 'PostgreSQL',
        5900 => 'VNC',
        8080 => 'HTTP Proxy',
        8443 => 'HTTPS Alt',
        27017 => 'MongoDB'
      }
      
      common_ports[port]
    end
  end
end

