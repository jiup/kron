require_relative '../../kron/constant'
require_relative '../domain/changeset'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module ChangesetAccessor
      def init_dir(overwrite = false)
        raise StandardError, 'directory \'changeset\' already exists' if !overwrite && Dir.exist?(CHANGESET_DIR)

        FileUtils.mkdir_p CHANGESET_DIR
      end

      def remove_dir
        FileUtils.remove_dir(CHANGESET_DIR, true)
      end

      def load_changeset(changeset)
        return changeset if changeset.rev_id.nil?

        src = File.join(CHANGESET_DIR, changeset.rev_id)
        return nil unless File.file? src

        Zlib::Inflate.inflate(File.read(src)).each_line do |line|
          params = line.chop.split(':', 2)
          changeset.put(params[0], params[-1])
        end
        changeset
      end

      def sync_changeset(changeset)
        return unless (changeset.instance_of? Kron::Domain::Changeset) && !changeset.rev_id.nil?

        src = File.join(CHANGESET_DIR, changeset.rev_id)
        f = File.open(src, 'w+')
        line = ''
        changeset.each_attr do |attr, value|
          value = value.join('') if value.is_a? Array
          line += attr.to_s + ':' + value.to_s + "\n"
        end
        f.syswrite(Zlib::Deflate.deflate(line))
        f.close
      end
    end
  end
end
