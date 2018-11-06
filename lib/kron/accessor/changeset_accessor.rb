require_relative '../../kron/constant'
require_relative '../domain/changeset'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module ChangesetAccessor

      def init_dir(overwrite=false)
        raise StandardError, 'directory \'changeset\' already exists' if !overwrite && Dir.exist?(CHANGESET_DIR)
        FileUtils.mkdir_p CHANGESET_DIR
      end

      def remove_dir
        FileUtils.remove_dir CHANGESET_DIR, true
      end

      def load_changeset(rev_id)
        src = File.join(CHANGESET_DIR, rev_id)
        raise IOError, "Cannot find the file !" unless File.file? src

        chgst = Kron::Domain::Changeset.new(rev_id)
        Zlib::Inflate.inflate(File.read(src)).each_line do |line|
          params = line.chop.split(" ",2)
          chgst.put(params[0],params[-1])
        end
        chgst
      end

      def sync_changeset(changeset)
        src = File.join(CHANGESET_DIR, "#{changeset.revid}")
        f = File.open(src,"w")
        line = ""
        changeset.each_attr do |attr, value|
          line += "#{attr}" + " " + "#{value}" + "\n"
        end
        f.syswrite(Zlib::Deflate.deflate(line))
        f.close
      end
    end
  end
end
