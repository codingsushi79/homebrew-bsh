# frozen_string_literal: true

module Bsh
  class CLI
    def self.start(args)
      new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
      command = @args.shift

      case command
      when 'interfaces', 'if'
        show_interfaces
      when 'ip'
        show_ip_info
      when 'scan', 'devices'
        scan_network
      when 'ports'
        scan_ports
      when 'device', 'info'
        show_device_info
      when 'users'
        enumerate_users
      when 'search'
        search_user
      when 'help', '-h', '--help', nil
        show_help
      else
        puts "Unknown command: #{command}"
        puts
        show_help
        exit 1
      end
    end

    private

    def show_interfaces
      NetworkInfo.show_interfaces
    end

    def show_ip_info
      target = @args.shift || 'local'
      IPInfo.show(target)
    end

    def scan_network
      network = @args.shift
      DeviceScanner.scan(network)
    end

    def scan_ports
      host = @args.shift || 'localhost'
      ports = @args.map(&:to_i)
      ports = [22, 80, 443, 8080, 3000] if ports.empty?
      PortScanner.scan(host, ports)
    end

    def show_device_info
      ip = @args.shift
      if ip.nil?
        puts "Error: IP address required"
        puts "Usage: bsh device <ip_address>"
        puts "Example: bsh device 192.168.1.1"
        exit 1
      end
      DeviceInfo.show(ip)
    end

    def enumerate_users
      ip = @args.shift
      if ip.nil?
        puts "Error: IP address required"
        puts "Usage: bsh users <ip_address>"
        puts "Example: bsh users 192.168.1.1"
        exit 1
      end
      require 'bsh/user_enum'
      UserEnum.enumerate(ip)
    end

    def search_user
      ip = @args.shift
      username = @args.shift
      if ip.nil? || username.nil?
        puts "Error: IP address and username required"
        puts "Usage: bsh search <ip_address> <username>"
        puts "Example: bsh search 192.168.1.1 admin"
        exit 1
      end
      require 'bsh/user_enum'
      UserEnum.search(ip, username)
    end

    def show_help
      puts <<~HELP
        BSH - Basic Hacker Tools
        ========================

        Commands:
          interfaces, if    Show network interfaces and their information
          ip [target]       Show IP address information (default: local)
          scan [network]    Scan network for devices (default: local network)
          ports [host]      Scan ports on a host (default: localhost)
          device, info [ip] Show detailed device information for an IP
          users [ip]        Enumerate possible users on a device
          search [ip] [user] Search for a specific user on a device
          help              Show this help message

        Examples:
          bsh interfaces
          bsh ip
          bsh ip 8.8.8.8
          bsh scan
          bsh scan 192.168.1.0/24
          bsh ports localhost
          bsh ports 192.168.1.1 22 80 443
          bsh device 192.168.1.1
          bsh info 192.168.1.100
          bsh users 192.168.1.1
          bsh search 192.168.1.1 admin

        Note: These tools are for information gathering only. They do not
        perform any hacking or unauthorized access attempts.
      HELP
    end
  end
end

