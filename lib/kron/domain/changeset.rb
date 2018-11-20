require 'colorize'
module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :author, :added_files,
                    :modified_files, :deleted_files
      attr_reader :rev_id

      def initialize(rev_id = nil)
        @rev_id = rev_id
        @author = ''
        @commit_message = ''
        @timestamp = Time.now.asctime
        @added_files = Set.new
        @modified_files = Set.new
        @deleted_files = Set.new
      end

      def rev_id=(rev_id)
        raise 'value reassigned' unless @rev_id.nil?

        @rev_id = rev_id
      end

      def put(param, value)
        raise StandardError, 'Cannot find this attribute in changeset!' unless instance_variable_get(param)

        if param =~ /@*_files/
          # value = value.split(' ')
          instance_variable_get(param).add(value)
        else
          instance_variable_set(param, value)
        end
      end

      def each_attr
        instance_variables.each do |ivar|
          value = instance_variable_get(ivar)
          yield ivar, value
        end
      end

      def get(param)
        instance_variable_get(param)
      end

      def to_s
        buffer = StringIO.new
        instance_variables.each do |ivar|
          unless ivar.to_s =~(/@*_files|@rev_id|@timestamp/) || (instance_variable_get(ivar) == "")
            buffer << "#{ivar}: "[1..-1].capitalize
            buffer.puts instance_variable_get(ivar)
          end
        end
        buffer.puts "Time: #{Time.at(@timestamp.to_i)}"
        @added_files.each { |e| buffer.puts "        new file: #{e}".colorize(color: :green) }
        @modified_files.each { |f| buffer.puts "        modified: #{f}".colorize(color: :yellow) }
        @deleted_files.each { |f| buffer.puts "        deleted: #{f}".colorize(color: :red) }
        buffer.puts ''
        buffer
      end
    end
  end
end