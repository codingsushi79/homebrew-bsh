#!/usr/bin/env ruby
# frozen_string_literal: true

# Find lib directory - works in both development and Homebrew installation
script_path = File.expand_path(__FILE__)
script_dir = File.dirname(script_path)

# Try Homebrew installation path first (libexec/lib)
libexec_path = File.expand_path(File.join(script_dir, '..', 'libexec', 'lib'))
if File.exist?(libexec_path)
  lib_path = libexec_path
else
  # Development mode - lib is relative to script directory
  lib_path = File.expand_path(File.join(script_dir, 'lib'))
end

$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require 'bsh/cli'
require 'bsh/network_info'
require 'bsh/ip_info'
require 'bsh/device_scanner'
require 'bsh/port_scanner'

Bsh::CLI.start(ARGV)

