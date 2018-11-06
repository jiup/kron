require 'kron/constant'

module Kron
  module Helper
    class RepoFetcher
      def self.from(_uri, _overwrite = false)
        raise NotImplementedError
      end
    end

    class LocalFetcher < RepoFetcher
      def self.from(uri, overwrite = false)
        src = File.join(uri, '.kron')
        raise StandardError, "No repository found at '#{uri}'" unless Dir.exist?(src)
        raise StandardError, 'Repository already exists' if !overwrite && Dir.exist?(KRON_DIR)

        FileUtils.cp_r(src, BASE_DIR)
        # TODO: parse HEAD revision and recovery the working directory
      end
    end

    class RemoteFetcher < RepoFetcher
      def self.from(_uri, _overwrite = false)
        raise NotImplementedError
      end
    end
  end
end