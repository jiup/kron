require 'kron/constant'
require 'kron/domain/index'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module IndexAccessor
      def init_index(overwrite = false)
        raise StandardError, 'file \'index\' already exists' if !overwrite && File.exist?(INDEX_PATH)

        File.open(INDEX_PATH, 'w+')
      end

      def remove_index
        FileUtils.rm_f INDEX_PATH
      end

      def load_index
        idx = Kron::Domain::Index.new
        src = INDEX_PATH
        return idx unless File.file?(src) && File.size(src) > 0

        Zlib::Inflate.inflate(File.read(src)).each_line do |line|
          idx.put(line.chop.reverse.split(' ', 5).map(&:reverse).reverse)
        end
        idx
      end

      def sync_index(idx)
        s_buf = StringIO.new
        idx.each_pair { |path, attr| s_buf << "#{path} #{attr * ' '}\n" }
        dst = INDEX_PATH
        File.open(dst, 'w+') { |f| f.write(Zlib::Deflate.deflate(s_buf.string)) }
      end
    end
  end
end