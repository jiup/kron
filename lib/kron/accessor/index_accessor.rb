require_relative '../../kron/constant'
require_relative '../domain/index'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module IndexAccessor

      def init_file(overwrite = false)
        raise StandardError, 'stage already exists' if !overwrite && File.exist?(INDEX_PATH)
        File.new(INDEX_PATH)
      end

      def remove_file
        File.delete(INDEX_PATH)
      end

      def load_index
        raise NotImplementedError
      end

      def sync_index
        raise NotImplementedError
      end
    end
  end
end