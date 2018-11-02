module RevAccessor
  def load_rev
    raise NotImplementedError
  end

  def sync_rev
    raise NotImplementedError
  end
end