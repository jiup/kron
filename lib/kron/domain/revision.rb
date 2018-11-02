require_relative '../../../lib/kron/accessor/manifest_accessor'
require_relative '../../../lib/kron/accessor/changeset_accessor'

class Revision
  include ManifestAccessor
  attr_accessor :p_id, :id, :token, :changeset
  # def manifest
  #   manifest ||= load_manifest(id)
  # end
end