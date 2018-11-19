require 'kron/constant'
require 'net/http'
require 'open-uri'

module Kron
  module Helper
    class RepoFetcher
      def self.from(uri, dst, overwrite = false, verbose = false)
        res = URI(uri)
        begin
          case res.scheme
          when nil
            print "Fetching local repository from '#{res}'... " if verbose
            LocalFetcher.from(uri, dst, overwrite)
            puts 'Done' if verbose
            return true # working directory recovery needed
          when 'http'
            print "Fetching remote repository from '#{res}'... " if verbose
            RemoteFetcher.from(uri, dst, overwrite)
            puts 'Done' if verbose
          else
            STDERR.puts "Protocol not support: '#{res.scheme}'"
          end
        rescue StandardError => e
          puts 'Failed' if verbose
          STDERR.puts e.message
        end
        false # no further actions needed
      end
    end

    class LocalFetcher < RepoFetcher
      def self.from(uri, dir = BASE_DIR, overwrite = false)
        src = File.join(uri, '.kron')
        raise StandardError, "No repository found at '#{uri}'" unless Dir.exist?(src)
        raise StandardError, 'Repository already exists' if !overwrite && (dir == BASE_DIR) && Dir.exist?(KRON_DIR)

        FileUtils.mkdir_p dir
        FileUtils.cp_r(src, dir)
      end
    end

    class RemoteFetcher < RepoFetcher
      def self.from(uri, dir = BASE_DIR, overwrite = false)
        basename = File.basename(uri)
        raise StandardError, 'Not a kron repository' unless File.extname(uri).eql?('.kron')
        raise StandardError, 'Repository already exists' if !overwrite && (dir == BASE_DIR) && File.exist?(basename)

        FileUtils.mkdir_p dir
        IO.copy_stream(open(uri), File.join(dir, basename))
      end
    end
  end
end