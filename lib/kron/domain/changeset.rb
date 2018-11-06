module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :account, :username, :added_files, :modified_files, :deleted_files

      def initialize

      end

      def install(lines)
        attrs = lines.split("/n")
        attrs.each do |attr|
          
        end
      end

    end
  end
end