# frozen_string_literal: true

require 'socket'

module Bsh
  class NetworkInfo
    def self.show_interfaces
      puts "Network Interfaces"
      puts "=" * 60
      puts

      interfaces = Socket.getifaddrs

      interfaces.each do |ifaddr|
        next if ifaddr.addr.nil?
        next unless ifaddr.addr.ipv4? || ifaddr.addr.ipv6?

        puts "Interface: #{ifaddr.name}"
        
        if ifaddr.addr.ipv4?
          puts "  Type: IPv4"
          puts "  IP: #{ifaddr.addr.ip_address}"
          puts "  Netmask: #{ifaddr.netmask&.ip_address || 'N/A'}"
        elsif ifaddr.addr.ipv6?
          puts "  Type: IPv6"
          puts "  IP: #{ifaddr.addr.ip_address}"
          puts "  Netmask: #{ifaddr.netmask&.ip_address || 'N/A'}"
        end

        puts
      end

      # Show default gateway (if available)
      show_default_gateway
    end

    def self.show_default_gateway
      begin
        # Try to get default route on macOS/Linux
        if RUBY_PLATFORM.include?('darwin')
          route = `route -n get default 2>/dev/null | grep gateway`.strip
          puts "Default Gateway: #{route.split(':').last&.strip || 'Not available'}"
        elsif RUBY_PLATFORM.include?('linux')
          route = `ip route | grep default`.strip
          gateway = route.split(/\s+/)[2]
          puts "Default Gateway: #{gateway || 'Not available'}"
        end
      rescue StandardError
        puts "Default Gateway: Not available"
      end
      puts
    end
  end
end

