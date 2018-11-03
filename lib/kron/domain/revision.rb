require_relative '../../../lib/kron/accessor/manifest_accessor'
require_relative '../../../lib/kron/accessor/changeset_accessor'

class Revision
  include ChangesetAccessor
  include ManifestAccessor

  attr_accessor :p_id, :id, :token
  attr_writer :manifest, :changeset

  def manifest
    manifest ||= load_manifest(id) unless id.nil?
  end

  def changeset
    changeset ||= load_changeset(id) unless id.nil?
  end
end