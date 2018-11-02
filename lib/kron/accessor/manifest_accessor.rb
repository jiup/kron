module ManifestAccessor
  def load_manifest(revition_id)
    raise NotImplementedError
  end

  def sync_manifest
    raise NotImplementedError
  end
end