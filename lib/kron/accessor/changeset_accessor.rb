require 'kron/constant'
require 'kron/domain/changeset'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module ChangesetAccessor
      def init_changeset_dir(overwrite = false)
        raise StandardError, 'directory \'changeset\' already exists' if !overwrite && Dir.exist?(CHANGESET_DIR)

        FileUtils.mkdir_p CHANGESET_DIR
      end

      def remove_changeset_dir
        FileUtils.remove_dir(CHANGESET_DIR, true)
      end

      def load_changeset(changeset)
        return changeset if changeset.rev_id.nil?

        src = File.join(CHANGESET_DIR, changeset.rev_id)
        return nil unless File.file? src

        Zlib::Inflate.inflate(File.read(src)).each_line do |line|
          params = line.chop.split(':', 2)
          if params[0] =~ /@*_files/
            params[-1].split(',').each do |v|
              changeset.put(params[0], v)
            end
          else
            changeset.put(params[0], params[-1])
          end
        end
        changeset
      end

      def sync_changeset(changeset)
        return unless (changeset.instance_of? Kron::Domain::Changeset) && !changeset.rev_id.nil?

        src = File.join(CHANGESET_DIR, changeset.rev_id)
        f = File.open(src, 'w+')
        line = ''
        changeset.each_attr do |attr, value|
          line += attr.to_s + ':'
          if value.is_a? Set
            value_buffer = ''
            value.each{|e| value_buffer += "#{e},"}
            value = value_buffer
          else
            value = value.to_s
          end
          line += value.to_s + "\n"
        end
        f.syswrite(Zlib::Deflate.deflate(line))
        f.close
      end
    end
  end
end