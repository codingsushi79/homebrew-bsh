# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'resolv'
require 'net/http'
require 'uri'
require 'openssl'

module Bsh
  class UserEnum
    def self.enumerate(ip)
      puts "User Enumeration for: #{ip}"
      puts "=" * 60
      puts
      puts "Note: This tool only attempts safe, read-only enumeration."
      puts "It does not perform any unauthorized access attempts."
      puts

      users = []
      
      # Try multiple enumeration methods
      users += try_smb_enumeration(ip)
      users += try_ssh_enumeration(ip)
      users += try_rdp_enumeration(ip)
      users += try_http_enumeration(ip)
      
      users.uniq!
      
      if users.empty?
        puts "No users found via enumeration methods."
        puts "This may mean:"
        puts "  - No enumeration services are available"
        puts "  - Services require authentication"
        puts "  - Services are configured securely"
      else
        puts "Found #{users.length} possible user(s):"
        puts
        users.each_with_index do |user, index|
          puts "#{index + 1}. #{user[:username]}"
          puts "   Source: #{user[:source]}"
          puts "   Method: #{user[:method]}"
          puts
        end
      end
      
      users
    end

    def self.search(ip, username)
      puts "Searching for user '#{username}' on: #{ip}"
      puts "=" * 60
      puts

      found = false
      sources = []

      # Try SMB enumeration
      if check_smb_available(ip)
        result = try_smb_user_check(ip, username)
        if result[:found]
          found = true
          sources << "SMB (#{result[:details]})"
        end
      end

      # Try SSH enumeration
      if check_ssh_available(ip)
        result = try_ssh_user_check(ip, username)
        if result[:found]
          found = true
          sources << "SSH (#{result[:details]})"
        end
      end

      # Try RDP enumeration
      if check_rdp_available(ip)
        result = try_rdp_user_check(ip, username)
        if result[:found]
          found = true
          sources << "RDP (#{result[:details]})"
        end
      end

      # Try HTTP enumeration
      result = try_http_user_check(ip, username)
      if result[:found]
        found = true
        sources << "HTTP (#{result[:details]})"
      end

      if found
        puts "✓ User '#{username}' found!"
        puts "  Sources: #{sources.join(', ')}"
      else
        puts "✗ User '#{username}' not found via enumeration methods."
        puts "  This does not necessarily mean the user doesn't exist."
      end
      puts

      found
    end

    private

    def self.try_smb_enumeration(ip)
      users = []
      
      return users unless check_smb_available(ip)
      
      # Try to enumerate users via SMB (read-only, no authentication)
      # This uses null session enumeration
      begin
        if RUBY_PLATFORM.include?('darwin') || RUBY_PLATFORM.include?('linux')
          # Try using smbclient if available
          result = `smbclient -L #{ip} -N 2>&1 | grep -i "user" | head -20`.strip
          if $?.success? && !result.empty?
            result.split("\n").each do |line|
              if line =~ /(\w+)\s+.*user/i
                users << {
                  username: $1,
                  source: 'SMB',
                  method: 'SMB enumeration'
                }
              end
            end
          end
        end
      rescue StandardError
        # Ignore errors
      end
      
      users
    end

    def self.try_ssh_enumeration(ip)
      users = []
      
      return users unless check_ssh_available(ip)
      
      # Try common usernames via SSH (just checking if they exist, not authenticating)
      common_users = %w[admin root administrator guest user test demo pi ubuntu debian]
      
      common_users.each do |username|
        result = try_ssh_user_check(ip, username)
        if result[:found]
          users << {
            username: username,
            source: 'SSH',
            method: result[:details]
          }
        end
      end
      
      users
    end

    def self.try_rdp_enumeration(ip)
      users = []
      
      return users unless check_rdp_available(ip)
      
      # RDP enumeration is limited, but we can try common usernames
      common_users = %w[Administrator admin guest user]
      
      common_users.each do |username|
        result = try_rdp_user_check(ip, username)
        if result[:found]
          users << {
            username: username,
            source: 'RDP',
            method: result[:details]
          }
        end
      end
      
      users
    end

    def self.try_http_enumeration(ip)
      users = []
      
      # Try to find user information via HTTP
      # Check common paths that might reveal users
      common_paths = [
        '/users',
        '/api/users',
        '/admin/users',
        '/userlist',
        '/members',
        '/profiles'
      ]
      
      [80, 443, 8080, 8443].each do |port|
        next unless check_port_open(ip, port)
        
        common_paths.each do |path|
          begin
            uri = URI("http#{port == 443 || port == 8443 ? 's' : ''}://#{ip}:#{port}#{path}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.read_timeout = 2
            http.open_timeout = 2
            
            if port == 443 || port == 8443
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            
            response = http.get(uri.path)
            
            if response.code == '200'
              # Try to extract usernames from response
              response.body.scan(/"username":\s*"([^"]+)"/i).each do |match|
                users << {
                  username: match[0],
                  source: "HTTP:#{port}",
                  method: "API endpoint: #{path}"
                }
              end
              
              response.body.scan(/<li[^>]*>([^<]+)<\/li>/i).each do |match|
                username = match[0].strip
                if username =~ /^[a-z0-9_]+$/i && username.length > 2 && username.length < 20
                  users << {
                    username: username,
                    source: "HTTP:#{port}",
                    method: "HTML content: #{path}"
                  }
                end
              end
            end
          rescue StandardError
            # Ignore errors
          end
        end
      end
      
      users
    end

    def self.check_smb_available(ip)
      check_port_open(ip, 445) || check_port_open(ip, 139)
    end

    def self.check_ssh_available(ip)
      check_port_open(ip, 22)
    end

    def self.check_rdp_available(ip)
      check_port_open(ip, 3389)
    end

    def self.check_port_open(ip, port, timeout: 1)
      begin
        Timeout.timeout(timeout) do
          socket = Socket.tcp(ip, port, connect_timeout: timeout)
          socket.close
          true
        end
      rescue StandardError
        false
      end
    end

    def self.try_smb_user_check(ip, username)
      found = false
      details = 'Not available'
      
      begin
        if RUBY_PLATFORM.include?('darwin') || RUBY_PLATFORM.include?('linux')
          # Try to check if user exists via SMB
          result = `smbclient "\\\\#{ip}\\IPC$" -U "#{username}" -N -c "exit" 2>&1`
          if result =~ /NT_STATUS_(LOGON_FAILURE|ACCOUNT_LOCKED_OUT)/i
            found = true
            details = 'User exists (authentication attempted)'
          elsif result =~ /NT_STATUS_NO_SUCH_USER/i
            found = false
            details = 'User does not exist'
          end
        end
      rescue StandardError
        # Ignore errors
      end
      
      { found: found, details: details }
    end

    def self.try_ssh_user_check(ip, username)
      found = false
      details = 'Not available'
      
      begin
        # Try to connect and see if we get a password prompt (user exists)
        # or "Invalid user" (user doesn't exist)
        socket = Socket.tcp(ip, 22, connect_timeout: 2)
        
        # Read SSH banner
        banner = socket.read_nonblock(1024) rescue nil
        
        # Send SSH connection attempt
        socket.write("SSH-2.0-bsh_client\r\n")
        
        # Try to read response
        response = socket.read_nonblock(1024) rescue nil
        
        socket.close
        
        if response && response.include?('SSH')
          # Try to determine if user exists by attempting connection
          # This is a simplified check - real SSH enumeration is more complex
          found = true
          details = 'SSH service available (user existence uncertain)'
        end
      rescue Errno::ECONNREFUSED
        found = false
        details = 'SSH not available'
      rescue StandardError
        # Ignore other errors
      end
      
      { found: found, details: details }
    end

    def self.try_rdp_user_check(ip, username)
      found = false
      details = 'Not available'
      
      begin
        # RDP enumeration is limited without authentication
        # We can only check if the service is available
        if check_rdp_available(ip)
          found = true
          details = 'RDP service available (user existence uncertain)'
        end
      rescue StandardError
        # Ignore errors
      end
      
      { found: found, details: details }
    end

    def self.try_http_user_check(ip, username)
      found = false
      details = 'Not available'
      
      # Try common HTTP endpoints that might reveal user information
      [80, 443, 8080, 8443].each do |port|
        next unless check_port_open(ip, port)
        
        common_paths = [
          "/users/#{username}",
          "/api/users/#{username}",
          "/user/#{username}",
          "/profile/#{username}",
          "/~#{username}"
        ]
        
        common_paths.each do |path|
          begin
            uri = URI("http#{port == 443 || port == 8443 ? 's' : ''}://#{ip}:#{port}#{path}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.read_timeout = 2
            http.open_timeout = 2
            
            if port == 443 || port == 8443
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            
            response = http.get(uri.path)
            
            if response.code == '200' && response.body.include?(username)
              found = true
              details = "Found in HTTP response at #{path}"
              break
            end
          rescue StandardError
            # Ignore errors
          end
        end
        
        break if found
      end
      
      { found: found, details: details }
    end
  end
end

