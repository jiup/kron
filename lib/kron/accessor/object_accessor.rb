module ObjectAccessor
  def load_object(revition_id)
    raise NotImplementedError
  end

  def sync_object
    raise NotImplementedError
  end
end