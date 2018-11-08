module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :author, :added_files, :modified_files, :deleted_files
      # attr_reader :revid
    def initialize
      @commit_message = @author = ""
      @timestamp = Time.now.asctime
      @added_files = @modified_files = @deleted_files = []
    end

      def put(param,value)
        raise StandardError, "Cannot find this attribute in changeset!" unless instance_variable_get(param)
        if param =~ /@*_files/
          value = value.split(" ")
        end
       instance_variable_set(param,value)
      end

      def each_attr(&blk)
        instance_variables.each do |ivar|
          value = instance_variable_get(ivar)
          yield ivar, value
        end
      end

      def get(param)
        instance_variable_get(param)
      end

      def to_s
        message = ""
        instance_variables.each do |ivar|
          lines = "#{ivar}" + ":"
          if "#{ivar}" =~ /@*_files/
            instance_variable_get(ivar).each do |val|
              lines += val
            end
            elsif "#{ivar}" != "@revid"
              lines += instance_variable_get(ivar)
          end
          message += lines+"\n"
        end
       message
      end

    end
  end
end

# a = Kron::Domain::Changeset.new(1)
# a.put("@commit_message", "time runs out")
# # a.each_attr{|a,v| p a,v}
# print a.to_s