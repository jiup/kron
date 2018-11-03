module Kron
  module Helper
    class RepoFetcher
      def self.from(uri = nil)
        raise NotImplementedError
      end
    end

    class LocalFetcher < Fetcher
    end

    class RemoteFetcher < Fetcher
    end
  end
end