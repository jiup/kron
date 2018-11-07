require 'kron/accessor/manifest_accessor'
require 'kron/accessor/changeset_accessor'

module Kron
  module Domain
    class Revision
      include Kron::Accessor::ChangesetAccessor
      include Kron::Accessor::ManifestAccessor

      attr_accessor :p_node, :id, :token
      attr_writer :manifest, :changeset

      def manifest
        manifest ||= load_manifest(id) unless id.nil?
      end

      def changeset
        changeset ||= load_changeset(id) unless id.nil?
      end
    end
  end
end