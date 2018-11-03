module Kron
  class Repository
    def clone
      RepoFetcher.from(nil)
      raise NotImplementedError
    end
  end
end