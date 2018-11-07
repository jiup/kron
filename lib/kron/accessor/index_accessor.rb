require 'kron/constant'
require 'kron/domain/index'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module IndexAccessor

      def init_dir(overwrite = false)
        raise StandardError, 'directory \'index\' already exists' if !overwrite && Dir.exist?(INDEX_DIR)

        FileUtils.mkdir_p INDEX_PATH
      end

      # def remove_dir
      #   FileUtils.remove_dir INDEX_PATH , true
      # end

      def load_index
        idx = Kron::Domain::Index.new

        src = File.join(INDEX_PATH)
        return idx unless File.file? src

        Zlib::Inflate.inflate(File.read(src)).each_line do |line|
          idx.put(line.chop.reverse.split(' ', 5).map(&:reverse).reverse)
        end
        idx
      end

      def sync_index(idx)
        s_buf = StringIO.new
        idx.each_pair { |path, attr| s_buf << "#{path} #{attr * ' '}\n" }
        dst = File.join(INDEX_PATH)
        File.open(dst, 'w+') { |f| f.write(Zlib::Deflate.deflate(s_buf.string)) }
      end
    end
  end
end