module Kron
  module Domain
    class Changeset
      attr_accessor :commit_message, :timestamp, :account, :username, :added_files, :modified_files, :deleted_files
    end
  end
end