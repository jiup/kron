module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :account, :username, :added_files, :modified_files, :deleted_files
      attr_reader :revid
    def initialize(revid)
      @revid = revid
      @commit_message = @account = @username = ""
      @timestamp = Time.now.asctime
      @added_files = @modified_files = @deleted_files = []
    end

      def put(param,value)
        raise StandardError, "Cannot find this attribute in changeset!" unless instance_variable_get('@'+param)
       instance_variable_set('@'+param,value)
      end

      def each_attr(&blk)
        instance_variables.each do |ivar|
          value = instance_variable_get(ivar)
          yield ivar, value
        end
      end
    end
  end
end

a = Kron::Domain::Changeset.new(1)
a.put("commit_message", "time runs out")
a.each_attr{|a,v| p a,v}
