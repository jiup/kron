module ChangesetAccessor
  def load_changeset(revition_id)
    raise NotImplementedError
  end

  def sync_changeset
    raise NotImplementedError
  end
end