module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :author, :added_files,
                    :modified_files, :deleted_files
      attr_reader :rev_id

      def initialize(rev_id = nil)
        @rev_id = rev_id
        @commit_message = @author = ''
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
          #value = value.split(' ')
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
          buffer << "#{ivar}: "
          if ivar.to_s =~ /@*_files/
            instance_variable_get(ivar).each do |val|
              buffer << val
            end
            buffer.puts ''
          elsif ivar.to_s != '@rev_id'
            buffer.puts instance_variable_get(ivar)
          end
        end
        buffer
      end
    end
  end
end

a = Kron::Domain::Changeset.new(1)
a.put("@added_files", "time runs out")
a.put("@added_files", "time runs out")
p a
# # a.each_attr{|a,v| p a,v}
# print a.to_s