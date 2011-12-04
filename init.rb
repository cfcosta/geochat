$:.unshift File.expand_path('geochat', File.dirname(__FILE__))
require 'optparse'

require 'config'
require 'geochat'

GeoChat::Config.configure do |c|
  c.host = '0.0.0.0'
  c.port = 9292
  c.logger.level = Logger::DEBUG
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

  options.on('-l', '--log-level LOG_LEVEL', String,
             'Change default log level') do |level|
    raise "Log level #{level} don't exists." unless Logger.const_defined?(level)
    GeoChat::Config.logger.level = Logger.const_get(level)
  end
end.parse!

GeoChat.start_server

