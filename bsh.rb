#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/bsh/cli'
require_relative 'lib/bsh/network_info'
require_relative 'lib/bsh/ip_info'
require_relative 'lib/bsh/device_scanner'
require_relative 'lib/bsh/port_scanner'

Bsh::CLI.start(ARGV)

