module Kron
  module Accessor
    module ManifestAccessor
      def load_manifest rev_id
        raise NotImplementedError
      end

      def sync_manifest
        raise NotImplementedError
      end
    end
  end
end