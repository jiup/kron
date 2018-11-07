module Kron
  module Accessor
    module RevAccessor
      # @param
      # path
      # @return
      # Return a revision obj
      def load_rev
        # begin
        # File.open(BASE_DIR + REV_FILE, "r") do |aFile|
        content = File.read(BASE_DIR + REV_FILE)
        content = content.force_encoding("ASCII-8BIT")
        # p content
        Marshal.load(content)
      end

      # @param
      # null
      # @return
      # state:true or false
      def sync_rev(revisions)
        content = Marshal.dump(revisions)
        File.open( BASE_DIR +REV_FILE, "w") do |aFile|
          aFile.puts(content)
        end
      end

      # add a revision to revtree
      def add_rev
        revision = Revision.new
        revision.id = Digest::SHA1.hexdigest revision.to_s
        if File.exists?(BASE_DIR +REV_FILE)
          revisions = load_rev
          revision.p_id = revisions.current
          #TODO using manifest_accessor to create a new manifest
          # TODO using changeset_accessor to create a new changeset
          revisions.current[1] = revision.id
          revisions.heads[revisions.current[0]] = revision.id
        else
          revision.p_id = 0
          revisions = Revisions.new
          revisions.heads = Hash.new
          revisions.heads.store("master", revision.id)
          revisions.current = ['master',revision.id]
          revisions.root = revision.id
        end
        sync_rev(revisions)
      end
    end
  end
end