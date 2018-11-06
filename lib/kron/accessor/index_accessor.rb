require_relative '../../kron/constant'
require_relative '../domain/index'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module IndexAccessor

      def init_file(overwrite = false)
        raise StandardError, 'stage already exists' if !overwrite && File.exist?(INDEX_PATH)
        f = File.new(INDEX_PATH,"w")
        f.close
      end

      def remove_file
        File.delete(INDEX_PATH)
      end

      def load_index
        idx = Kron::Domain::Index.new
        Zlib::Inflate.inflate(File.read(INDEX_PATH)).each_line do |line|
          idx.put(line.chop)
        end
        idx
      end

      def sync_index(idx)
        f = File.open(INDEX_PATH, "w")
        line = ""
        idx.each_index do |item|
          line += item + "\n"
        end
        f.syswrite(Zlib::Deflate.deflate(line))
        f.close
      end
    end
  end
end