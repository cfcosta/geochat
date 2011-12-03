$:.unshift File.expand_path('geochat', File.dirname(__FILE__))
require 'optparse'

require 'config'
require 'geochat'

GeoChat::Config.configure do |c|
  c.host = '0.0.0.0'
  c.port = 9292
end

OptionParser.new do |options|
  options.banner = 'Usage: init.rb [options]'

  options.on('-p', '--port PORT', Integer,
             'Run the service on the specified port') do |port|
    GeoChat::Config.port = port.to_i
  end

  options.on('-h', '--host HOST', String,
             'Run the service on the specified host') do |host|
    GeoChat::Config.host = host
  end
end

GeoChat.start_server

