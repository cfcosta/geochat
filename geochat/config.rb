require 'logger'

module GeoChat
  module Config
    class << self
      def configure
        yield self
      end

      def mattr_accessor(*names)
        names.each do |name|
          class_eval "def self.#{name}; @@#{name} ||= nil ; end"
          class_eval "def self.#{name}=(value); @@#{name} = value ; end"
        end
      end
    end

    mattr_accessor :host, :port, :logger
    def self.logger
      @@logger ||= Logger.new(STDOUT)
    end
  end
end
