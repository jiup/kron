module Kron
  module Accessor
    module ChangesetAccessor
      def load_changeset rev_id
        raise NotImplementedError
      end

      def sync_changeset
        raise NotImplementedError
      end
    end
  end
end