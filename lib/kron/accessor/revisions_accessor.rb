module Kron
  module Accessor
    module RevisionsAccessor

      # @param
      # path
      # @return
      # Return a revision obj
      def load_rev
        # p BASE_DIR
        path = REV_PATH.to_s
        if File.exists?(path)
          content = File.read(path)
          content = content.force_encoding("ASCII-8BIT")
          Marshal.load(content)
        else
          revisions = Kron::Domain::Revisions.new
          revisions.current = Array.new
          revisions.heads = Hash.new
          revisions.rev_map = Hash.new
          revisions.current << "master"
          revisions
        end

      end

      # @param
      # null
      # @return
      # state:true or false
      def sync_rev(revisions)
        path = REV_PATH.to_s
        content = Marshal.dump(revisions)
        # p path
        File.open(path, "w") do |aFile|
          aFile.syswrite(content)
        end
      end

      # add a revision to revtree

    end
  end
end