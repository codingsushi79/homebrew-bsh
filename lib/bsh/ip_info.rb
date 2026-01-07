# frozen_string_literal: true

require 'socket'
require 'resolv'

module Bsh
  class IPInfo
    def self.show(target)
      if target == 'local'
        show_local_ip
      else
        show_remote_ip(target)
      end
    end

    def self.show_local_ip
      puts "Local IP Information"
      puts "=" * 60
      puts

      # Get local IP addresses
      local_ips = []
      Socket.getifaddrs.each do |ifaddr|
        next if ifaddr.addr.nil?
        next unless ifaddr.addr.ipv4? || ifaddr.addr.ipv6?

        local_ips << {
          interface: ifaddr.name,
          ip: ifaddr.addr.ip_address,
          type: ifaddr.addr.ipv4? ? 'IPv4' : 'IPv6',
          netmask: ifaddr.netmask&.ip_address
        }
      end

      local_ips.each do |info|
        puts "Interface: #{info[:interface]}"
        puts "  IP Address: #{info[:ip]}"
        puts "  Type: #{info[:type]}"
        puts "  Netmask: #{info[:netmask] || 'N/A'}"
        puts
      end

      # Show hostname
      hostname = Socket.gethostname
      puts "Hostname: #{hostname}"
      
      # Show FQDN if available
      begin
        fqdn = Socket.gethostbyname(hostname)[0]
        puts "FQDN: #{fqdn}" if fqdn != hostname
      rescue StandardError
        # Ignore errors
      end
      puts
    end

    def self.show_remote_ip(target)
      puts "IP Information for: #{target}"
      puts "=" * 60
      puts

      # Try to resolve hostname to IP
      begin
        ip = Resolv.getaddress(target)
        puts "IP Address: #{ip}"
        puts
      rescue Resolv::ResolvError
        # If it's already an IP, use it
        if target =~ /^(\d{1,3}\.){3}\d{1,3}$/
          ip = target
          puts "IP Address: #{ip}"
          puts
        else
          puts "Error: Could not resolve #{target}"
          return
        end
      end

      # Try reverse DNS lookup
      begin
        hostname = Resolv.getname(ip)
        puts "Hostname: #{hostname}"
      rescue Resolv::ResolvError
        puts "Hostname: Not available (no reverse DNS)"
      end
      puts

      # Try to ping (just to show if host is reachable)
      show_reachability(ip)
    end

    def self.show_reachability(ip)
      puts "Reachability Test:"
      begin
        # Try to connect to a common port (80) with a short timeout
        socket = Socket.tcp(ip, 80, connect_timeout: 2)
        socket.close
        puts "  Status: Reachable (port 80 open)"
      rescue StandardError
        begin
          # Try ICMP ping via system command
          if RUBY_PLATFORM.include?('darwin')
            result = `ping -c 1 -W 1000 #{ip} 2>&1`
            if $?.success?
              puts "  Status: Reachable (responds to ping)"
            else
              puts "  Status: May not be reachable (no ping response)"
            end
          else
            result = `ping -c 1 -w 1 #{ip} 2>&1`
            if $?.success?
              puts "  Status: Reachable (responds to ping)"
            else
              puts "  Status: May not be reachable (no ping response)"
            end
          end
        rescue StandardError
          puts "  Status: Unknown (could not test)"
        end
      end
      puts
    end
  end
end

