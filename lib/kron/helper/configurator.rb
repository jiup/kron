require 'singleton'
require 'socket'
require 'yaml'

require 'kron/constant'

module Kron
  module Helper
    class Configurator
      include Singleton

      def initialize
        @config = File.exist?(CONFIG_PATH) ? YAML.load_file(CONFIG_PATH) : default_config
      end

      def []=(key, value)
        @config[key] = value
      end

      def [](key)
        @config[key]
      end

      def delete(key)
        @config.delete(key)
      end

      def has?(key)
        @config.key? key
      end

      def sync(verbose = false)
        File.write(CONFIG_PATH, @config.to_yaml)
        puts 'Configuration updated.' if verbose
      end

      def to_s
        if @config.empty?
          'Empty set.'
        else
          str_buf = StringIO.new
          limit = @config.keys.map(&:length).max
          @config.each do |k, v|
            str_buf << "#{(k.to_s + ':').capitalize.ljust(limit + 1)}   #{v}\n" unless v.nil?
          end
          str_buf.string
        end
      end

      private

      def default_config
        config = {}
        config['author'] = Socket.gethostname[/^[^.]+/]
        config
      end
    end
  end
end