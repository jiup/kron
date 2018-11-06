require '../domain/changeset'

module Kron
  module Accessor
    module ChangesetAccessor
      def load_changeset(file, rev_id)
        unless File::exist?(file)
          raise IOError
        end
        chst = changeset.new()
        File.open do |aFile|
          #decompress
          #fild the lines about rev_id
          chst.install(lines)
        end
       chst
      end

      def sync_changeset(chs1,chs2)

      end

      def init_changeset
        raise NotImplementedError
      end

      def add_changeset
        raise NotImplementedError
        return revid
      end

    end
  end
end