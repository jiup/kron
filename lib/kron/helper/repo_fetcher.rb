module Kron
  module Helper
    class RepoFetcher
      def self.from(uri = nil)
        raise NotImplementedError
      end
    end

    class LocalFetcher < RepoFetcher
    end

    class RemoteFetcher < RepoFetcher
    end
  end
end