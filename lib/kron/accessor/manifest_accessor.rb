require 'kron/constant'

module Kron
  module Accessor
    module ManifestAccessor
      def init_dir(overwrite = false)
        raise StandardError, 'directory \'manifest\' already exists' if !overwrite && Dir.exist?(MANIFEST_DIR)

        FileUtils.mkdir_p MANIFEST_DIR
      end

      def remove_dir
        FileUtils.remove_dir MANIFEST_DIR, true
      end

      def load_manifest(rev_id)
        raise NotImplementedError
      end

      def sync_manifest
        raise NotImplementedError
      end
    end
  end
end