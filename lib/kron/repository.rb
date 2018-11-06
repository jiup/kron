require 'kron/helper/repo_fetcher'

module Kron
  module Repository
    def clone(repo_uri, force = false, verbose = false)
      if Kron::Helper::RepoFetcher.from(repo_uri, force, verbose)
        # TODO: recovery the working directory from HEAD revision
      end
    end

    def serve(single_pass = true)
      # TODO: serve a packed repository for remote access
    end
  end
end