require 'kron/constant'
require 'net/http'
require 'open-uri'

module Kron
  module Helper
    class RepoFetcher
      def self.from(uri, overwrite = false, verbose = false)
        res = URI(uri)
        begin
          case res.scheme
          when nil
            print "Fetching local repository from '#{res}'... " if verbose
            LocalFetcher.from(uri, overwrite)
          when 'http'
            print "Fetching remote repository from '#{res}'... " if verbose
            RemoteFetcher.from(uri, overwrite)
          else
            STDERR.puts "Protocol not support: '#{res.scheme}'"
            return false
          end
          puts 'Done' if verbose
        rescue StandardError => e
          puts 'Failed' if verbose
          STDERR.puts e.message
          return false
        end
        true
      end
    end

    class LocalFetcher < RepoFetcher
      def self.from(uri, overwrite = false)
        src = File.join(uri, '.kron')
        raise StandardError, "No repository found at '#{uri}'" unless Dir.exist?(src)
        raise StandardError, 'Repository already exists' if !overwrite && Dir.exist?(KRON_DIR)

        FileUtils.cp_r(src, BASE_DIR)
      end
    end

    class RemoteFetcher < RepoFetcher
      def self.from(uri, overwrite = false)
        basename = File.basename(uri)
        raise StandardError, 'Not a kron repository' unless File.extname(uri).equal?('.kron')
        raise StandardError, 'Repository already exists' if !overwrite && File.exist?(basename)

        IO.copy_stream(open(uri), basename)
      end
    end
  end
end