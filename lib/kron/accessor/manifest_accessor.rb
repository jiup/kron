require 'kron/constant'
require 'kron/domain/manifest'
require 'zlib'

module Kron
  module Accessor
    module ManifestAccessor
      def init_dir(overwrite = false)
        raise StandardError, 'directory \'manifest\' already exists' if !overwrite && Dir.exist?(MANIFEST_DIR)

        FileUtils.mkdir_p MANIFEST_DIR
      end

      def remove_dir
        FileUtils.remove_dir(MANIFEST_DIR, true)
      end

      def load_manifest(rev_id)
        src = File.join(MANIFEST_DIR, rev_id)
        return nil unless File.file? src

        mf = Kron::Domain::Manifest.new(rev_id)
        Zlib::Inflate.inflate(File.read(src)).each_line do |row|
          mf.put(row.chop.reverse.split(' ', 5).map(&:reverse).reverse)
        end
        mf
      end

      def sync_manifest(manifest)
        return unless (manifest.instance_of? Kron::Domain::Manifest) && !manifest.rev_id.nil?

        s_buf = StringIO.new
        manifest.each_pair { |path, attr| s_buf << "#{path} #{attr * ' '}\n" }
        dst = File.join(MANIFEST_DIR, rev_id)
        File.open(dst, 'w+') { |f| f.write(Zlib::Deflate.deflate(s_buf.string)) }
      end
    end
  end
end