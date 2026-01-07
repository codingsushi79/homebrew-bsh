# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'resolv'

module Bsh
  class DeviceScanner
    def self.scan(network = nil)
      puts "Network Device Scanner"
      puts "=" * 60
      puts
      puts "Note: This tool only scans for devices on your local network."
      puts "It does not perform any unauthorized access attempts."
      puts
      puts

      if network.nil?
        network = detect_local_network
      end

      if network.nil?
        puts "Error: Could not detect local network. Please specify a network range."
        puts "Example: bsh scan 192.168.1.0/24"
        return
      end

      puts "Scanning network: #{network}"
      puts "This may take a while..."
      puts

      devices = scan_network_range(network)
      
      if devices.empty?
        puts "No devices found on the network."
      else
        puts "Found #{devices.length} device(s):"
        puts
        devices.each_with_index do |device, index|
          puts "#{index + 1}. #{device[:ip]}"
          puts "   MAC: #{device[:mac] || 'Unknown'}"
          puts "   Hostname: #{device[:hostname] || 'Unknown'}"
          puts
        end
      end
    end

    def self.detect_local_network
      # Get the first IPv4 interface that's not loopback
      Socket.getifaddrs.each do |ifaddr|
        next if ifaddr.addr.nil?
        next unless ifaddr.addr.ipv4?
        next if ifaddr.name == 'lo' || ifaddr.name.start_with?('lo')

        ip = ifaddr.addr.ip_address
        netmask = ifaddr.netmask&.ip_address

        if netmask
          # Calculate network address
          ip_parts = ip.split('.').map(&:to_i)
          mask_parts = netmask.split('.').map(&:to_i)
          
          network_parts = ip_parts.zip(mask_parts).map { |a, b| a & b }
          network = network_parts.join('.')
          
          # Calculate CIDR notation
          cidr = mask_parts.map { |m| m.to_s(2).count('1') }.sum
          
          return "#{network}/#{cidr}"
        end
      end

      nil
    end

    def self.scan_network_range(network)
      devices = []

      # Parse CIDR notation (e.g., 192.168.1.0/24)
      if network.include?('/')
        base_ip, cidr = network.split('/')
        cidr = cidr.to_i
      else
        # Assume /24 if not specified
        base_ip = network
        cidr = 24
      end

      # Calculate number of hosts
      hosts = 2**(32 - cidr) - 2
      base_parts = base_ip.split('.').map(&:to_i)
      
      # Limit scan to reasonable size (max 256 hosts)
      max_hosts = [hosts, 256].min
      
      puts "Scanning up to #{max_hosts} hosts..."
      puts

      threads = []
      mutex = Mutex.new

      (1..max_hosts).each do |i|
        # Calculate IP address
        ip_parts = base_parts.dup
        ip_parts[3] = (ip_parts[3] + i) % 256
        ip = ip_parts.join('.')

        threads << Thread.new do
          if host_reachable?(ip)
            hostname = get_hostname(ip)
            mac = get_mac_address(ip)
            
            mutex.synchronize do
              devices << {
                ip: ip,
                hostname: hostname,
                mac: mac
              }
              print "."
              $stdout.flush
            end
          end
        end

        # Limit concurrent threads
        if threads.length >= 50
          threads.each(&:join)
          threads.clear
        end
      end

      threads.each(&:join)
      puts
      puts

      devices
    end

    def self.host_reachable?(ip)
      # Try to ping the host
      begin
        if RUBY_PLATFORM.include?('darwin')
          result = `ping -c 1 -W 1000 #{ip} 2>&1`
        else
          result = `ping -c 1 -w 1 #{ip} 2>&1`
        end
        $?.success?
      rescue StandardError
        false
      end
    end

    def self.get_hostname(ip)
      begin
        Resolv.getname(ip)
      rescue Resolv::ResolvError
        nil
      end
    end

    def self.get_mac_address(ip)
      # Try to get MAC from ARP table
      begin
        if RUBY_PLATFORM.include?('darwin')
          arp_entry = `arp -n #{ip} 2>&1`.strip
          if arp_entry =~ /\(([0-9a-f]{1,2}[:-][0-9a-f]{1,2}[:-][0-9a-f]{1,2}[:-][0-9a-f]{1,2}[:-][0-9a-f]{1,2}[:-][0-9a-f]{1,2})\)/i
            $1.upcase
          end
        elsif RUBY_PLATFORM.include?('linux')
          arp_entry = `arp -n #{ip} 2>&1`.strip
          if arp_entry =~ /([0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2})/i
            $1.upcase
          end
        end
      rescue StandardError
        nil
      end
    end
  end
end

