require 'kron/accessor/revisions_accessor'
require 'kron/accessor/manifest_accessor'
module Kron
  module Domain
    class Revisions
      include Kron::Accessor::RevisionsAccessor
      include Kron::Accessor::ManifestAccessor
      # current:[branch_name,revision]
      attr_accessor :current, :heads, :branch_hook, :rev_map # :tips,  # a map<branch_name, revision_head>
      # revision = Revision.new
      # revision.id = Digest::SHA1.hexdigest revision.to_s
      def add_revision(revision)
        revision.p_node = @current[1]
        # TODO: using manifest_accessor to create a new manifest
        # TODO: using changeset_accessor to create a new changeset
        # sync_manifest(manifest)
        @current[1] = revision
        @heads.store(current[0], current[1])
        @branch_hook.add revision
        @rev_map.store(revision.id, revision)
      end

      # get rev using rev_id
      def get_revision(rev_id)
        rev_map.each { |key, value| value if key.equal? rev_id }
      end
    end
  end
end