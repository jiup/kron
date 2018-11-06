module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :account, :username, :added_files, :modified_files, :deleted_files
    def initialize
      @commit_message = "ttt"
    end
      def install(lines)
        raise NotImplementedError
      end

      def attrs
        instance_variables.map{|ivar| instance_variable_get ivar}
      end
    end
  end
end

a = Kron::Domain::Changeset.new
att=a.instance_variables[0]
p a.instance_variable_get(att)
