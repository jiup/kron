module StageAccessor
  def load_stage
    raise NotImplementedError
  end

  def sync_stage
    raise NotImplementedError
  end
end