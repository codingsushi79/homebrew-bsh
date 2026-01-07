# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'resolv'

module Bsh
  class DeviceInfo
    def self.show(ip)
      puts "Device Information for: #{ip}"
      puts "=" * 60
      puts
      puts "Note: This tool only gathers publicly available information."
      puts "It does not perform any unauthorized access attempts."
      puts

      info = gather_info(ip)
      display_info(info)
    end

    def self.gather_info(ip)
      info = {
        ip: ip,
        hostname: nil,
        mac_address: nil,
        device_type: 'Unknown',
        os_info: nil,
        open_ports: [],
        services: {},
        vendor: nil
      }

      # Get hostname
      info[:hostname] = get_hostname(ip)

      # Get MAC address
      info[:mac_address] = get_mac_address(ip)
      info[:vendor] = get_vendor_from_mac(info[:mac_address]) if info[:mac_address]

      # Scan common ports to determine device type and OS
      common_ports = [22, 23, 80, 443, 135, 139, 445, 3389, 8080, 8443]
      open_ports_info = scan_ports(ip, common_ports)
      info[:open_ports] = open_ports_info[:open_ports]
      info[:services] = open_ports_info[:services]

      # Determine device type based on open ports
      info[:device_type] = determine_device_type(info[:open_ports], info[:services])

      # Try to get OS information from banners and TTL
      info[:os_info] = detect_os(ip, info[:open_ports], info[:services])

      info
    end

    def self.get_hostname(ip)
      begin
        Resolv.getname(ip)
      rescue Resolv::ResolvError
        nil
      end
    end

    def self.get_mac_address(ip)
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

    def self.get_vendor_from_mac(mac)
      # Extract first 3 octets (OUI - Organizationally Unique Identifier)
      oui = mac.split(/[:-]/).first(3).join(':').upcase
      
      # Common vendor OUIs (simplified - in production, use a database)
      vendors = {
        '00:50:56' => 'VMware',
        '00:0C:29' => 'VMware',
        '00:1C:14' => 'Dell',
        '00:1E:C2' => 'Dell',
        '00:25:90' => 'Apple',
        '00:26:BB' => 'Apple',
        '00:23:DF' => 'Apple',
        'A4:C1:38' => 'Apple',
        'AC:DE:48' => 'Apple',
        '00:1B:44' => 'Cisco',
        '00:1E:13' => 'Cisco',
        '00:21:70' => 'HP',
        '00:23:24' => 'HP',
        '00:50:8B' => 'Intel',
        '00:1A:79' => 'Intel',
        '00:1E:67' => 'Intel',
        '00:15:17' => 'Microsoft',
        '00:0D:3A' => 'Microsoft',
        '00:1D:60' => 'Samsung',
        '00:23:39' => 'Samsung',
        '00:1F:E2' => 'Sony',
        '00:24:BE' => 'Sony',
        '00:1A:2B' => 'LG',
        '00:1E:75' => 'LG',
        '00:1C:62' => 'Netgear',
        '00:24:B2' => 'Netgear',
        '00:1F:33' => 'Linksys',
        '00:22:6B' => 'Linksys',
        '00:1A:70' => 'TP-Link',
        '00:27:19' => 'TP-Link',
        '00:1D:0F' => 'ASUS',
        '00:1E:8C' => 'ASUS',
        '00:1B:11' => 'Belkin',
        '00:22:93' => 'Belkin',
        '00:1E:58' => 'D-Link',
        '00:21:91' => 'D-Link',
        '00:1C:C0' => 'ZyXEL',
        '00:1F:D0' => 'ZyXEL',
        '00:1A:92' => 'Buffalo',
        '00:1E:40' => 'Buffalo',
        '00:1C:23' => 'Ubiquiti',
        '00:27:22' => 'Ubiquiti',
        '00:1B:63' => 'Raspberry Pi',
        'B8:27:EB' => 'Raspberry Pi',
        'DC:A6:32' => 'Raspberry Pi',
        'E4:5F:01' => 'Raspberry Pi',
        '00:1E:06' => 'Nintendo',
        '00:1F:32' => 'Nintendo',
        '00:1A:E9' => 'Nintendo',
        '00:1C:BE' => 'Nintendo',
        '00:1D:DC' => 'Nintendo',
        '00:1E:EA' => 'Nintendo',
        '00:1F:C5' => 'Nintendo',
        '00:21:47' => 'Nintendo',
        '00:22:4C' => 'Nintendo',
        '00:23:31' => 'Nintendo',
        '00:24:1C' => 'Nintendo',
        '00:25:A0' => 'Nintendo',
        '00:26:59' => 'Nintendo',
        '00:1B:21' => 'Intel',
        '00:1C:BF' => 'Intel',
        '00:1D:72' => 'Intel',
        '00:1E:64' => 'Intel',
        '00:1F:3C' => 'Intel',
        '00:21:5C' => 'Intel',
        '00:22:15' => 'Intel',
        '00:23:14' => 'Intel',
        '00:24:D6' => 'Intel',
        '00:25:00' => 'Intel',
        '00:26:18' => 'Intel',
        '00:27:10' => 'Intel'
      }
      
      vendors[oui]
    end

    def self.scan_ports(ip, ports)
      open_ports = []
      services = {}

      ports.each do |port|
        result = check_port_with_banner(ip, port)
        if result[:open]
          open_ports << port
          services[port] = {
            name: result[:service],
            banner: result[:banner],
            version: result[:version]
          }
        end
      end

      { open_ports: open_ports, services: services }
    end

    def self.check_port_with_banner(host, port, timeout: 2)
      begin
        Timeout.timeout(timeout) do
          socket = Socket.tcp(host, port, connect_timeout: timeout)
          
          banner = nil
          version = nil
          
          # Try to read banner for common services
          if [22, 21, 23, 25, 80, 443].include?(port)
            begin
              socket.read_nonblock(1024)
            rescue IO::WaitReadable
              # No data available
            rescue StandardError
              # Ignore errors
            end
          end
          
          socket.close
          
          service = get_service_name(port)
          { open: true, service: service, banner: banner, version: version }
        end
      rescue Errno::ECONNREFUSED
        { open: false }
      rescue Errno::ETIMEDOUT, Timeout::Error
        { open: false }
      rescue StandardError
        { open: false }
      end
    end

    def self.get_service_name(port)
      common_ports = {
        22 => 'SSH',
        23 => 'Telnet',
        80 => 'HTTP',
        443 => 'HTTPS',
        135 => 'MSRPC',
        139 => 'NetBIOS',
        445 => 'SMB',
        3389 => 'RDP',
        8080 => 'HTTP Proxy',
        8443 => 'HTTPS Alt'
      }
      
      common_ports[port]
    end

    def self.determine_device_type(open_ports, services)
      # Router/Gateway indicators
      if open_ports.include?(80) || open_ports.include?(443) || open_ports.include?(8080)
        if services[80] || services[443] || services[8080]
          # Check if it's a router web interface
          return 'Router/Gateway'
        end
      end

      # Server indicators
      if open_ports.include?(22) && open_ports.include?(80)
        return 'Server (Linux/Unix)'
      end

      if open_ports.include?(3389)
        return 'Windows Server/Workstation'
      end

      if open_ports.include?(445) || open_ports.include?(139)
        return 'Windows Device'
      end

      if open_ports.include?(22)
        return 'Linux/Unix Device'
      end

      if open_ports.include?(80) || open_ports.include?(443)
        return 'Web Server'
      end

      if open_ports.empty?
        return 'Unknown (No open ports detected)'
      end

      'Network Device'
    end

    def self.detect_os(ip, open_ports, services)
      os_hints = []

      # TTL-based OS detection (simplified)
      begin
        if RUBY_PLATFORM.include?('darwin')
          result = `ping -c 1 -W 1000 #{ip} 2>&1`
          if result =~ /ttl=(\d+)/i
            ttl = $1.to_i
            if ttl <= 64
              os_hints << 'Linux/Unix'
            elsif ttl <= 128
              os_hints << 'Windows'
            else
              os_hints << 'Network Device'
            end
          end
        else
          result = `ping -c 1 -w 1 #{ip} 2>&1`
          if result =~ /ttl=(\d+)/i
            ttl = $1.to_i
            if ttl <= 64
              os_hints << 'Linux/Unix'
            elsif ttl <= 128
              os_hints << 'Windows'
            else
              os_hints << 'Network Device'
            end
          end
        end
      rescue StandardError
        # Ignore errors
      end

      # Port-based OS detection
      if open_ports.include?(3389)
        os_hints << 'Windows (RDP detected)'
      end

      if open_ports.include?(445) || open_ports.include?(139)
        os_hints << 'Windows (SMB detected)'
      end

      if open_ports.include?(22)
        os_hints << 'Linux/Unix (SSH detected)'
      end

      os_hints.uniq.join(' or ')
    end

    def self.display_info(info)
      puts "IP Address: #{info[:ip]}"
      puts "Hostname: #{info[:hostname] || 'Not available'}"
      puts "MAC Address: #{info[:mac_address] || 'Not available'}"
      puts "Vendor: #{info[:vendor] || 'Unknown'}"
      puts
      puts "Device Type: #{info[:device_type]}"
      puts "OS Information: #{info[:os_info] || 'Unknown'}"
      puts
      
      if info[:open_ports].any?
        puts "Open Ports: #{info[:open_ports].join(', ')}"
        puts
        puts "Services:"
        info[:services].each do |port, service_info|
          puts "  Port #{port}: #{service_info[:name]}"
          if service_info[:banner]
            puts "    Banner: #{service_info[:banner]}"
          end
          if service_info[:version]
            puts "    Version: #{service_info[:version]}"
          end
        end
      else
        puts "Open Ports: None detected"
      end
      puts
      
      # Try to enumerate users
      if info[:open_ports].any?
        puts "Attempting user enumeration..."
        begin
          require 'bsh/user_enum'
          users = UserEnum.enumerate(info[:ip])
          if users.any?
            puts "Users found: #{users.map { |u| u[:username] }.join(', ')}"
          end
        rescue LoadError, StandardError => e
          puts "User enumeration unavailable: #{e.message}"
        end
        puts
      end
    end
  end
end

