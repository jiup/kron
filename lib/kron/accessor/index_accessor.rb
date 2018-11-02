module IndexAccessor
  def load_index
    raise NotImplementedError
  end

  def sync_index
    raise NotImplementedError
  end
end