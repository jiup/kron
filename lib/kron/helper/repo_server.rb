require 'socket'
require 'webrick'
require 'zip'
require 'kron/constant'

module Kron
  module Helper
    class RepoServer
      class HttpRepoServer < WEBrick::HTTPServlet::AbstractServlet
        COMPRESSED_KRON_PATH = KRON_DIR + 'compressed.kron'

        def initialize(server, multi_serve, quiet)
          super server
          @server = server
          @multi_serve = multi_serve
          @quiet = quiet
        end

        def do_GET(_req, resp)
          puts 'Preparing for response...' unless @quiet
          begin
            print "Compressing repository '#{WORKING_DIR}'... " unless @quiet
            ZipFileGenerator.new('.kron/', COMPRESSED_KRON_PATH).write
            puts 'Done' unless @quiet
          rescue StandardError => e
            puts 'Failed' unless @quiet
            puts e
          end
          resp.status = 200
          resp.body = File.new COMPRESSED_KRON_PATH
          FileUtils.rm_rf COMPRESSED_KRON_PATH
          puts 'Transfer completed!' unless @quiet
          return @server.shutdown unless @multi_serve

          puts 'End of service.' unless @quiet
        end

        def do_POST(_req, resp)
          resp.status = 503
          resp.body = '\'kron push\' not implemented.'
        end
      end

      def initialize(port, token = nil, multiple = false, quiet = false)
        unset = port.nil? ? true : false
        @port = unset ? port = 80 : port
        if port_open?(Socket.gethostname, port, 0.0001)
          raise StandardError "Port #{port} already in use" unless unset

          tmp_server = TCPServer.new('0.0.0.0', 0)
          @port = tmp_server.addr[1]
          tmp_server.close
          puts "Port #{port} already in use, configured #{@port} instead."
        end
        attrs = {}
        attrs[:Port] = @port
        attrs[:AccessLog] = []
        attrs[:Logger] = WEBrick::Log.new('/dev/null')
        @token = token
        @server = WEBrick::HTTPServer.new attrs
        @server.mount '/' + token + '.kron', HttpRepoServer, multiple, quiet
      end

      def serve
        trap('INT') { @server.shutdown }
        ip = IPSocket.getaddress(Socket.gethostname)
        puts "Service listening at 'http://#{ip}#{@port == 80 ? '' : ":#{@port}"}/#{@token}.kron'..."
        @server.start
      end

      def port_open?(ip, port, timeout)
        start_time = Time.now
        current_time = start_time
        while (current_time - start_time) <= timeout
          begin
            TCPSocket.new(ip, port)
            return true
          rescue Errno::ECONNREFUSED
            sleep 0.1
          end
          current_time = Time.now
        end
        false
      end
    end

    class ZipFileGenerator
      # Initialize with the directory to zip and the location of the output archive.
      def initialize(input_dir, output_file, quiet = true)
        @input_dir = input_dir
        @output_file = output_file
        @quiet = quiet
      end

      # Zip the input directory.
      def write
        entries = Dir.entries(@input_dir)
        entries.delete('.')
        entries.delete('..')
        io = Zip::File.open(@output_file, Zip::File::CREATE)
        write_entries(entries, '', io)
        io.close
      end

      private

      # A helper method to make the recursion work.
      def write_entries(entries, path, io)
        entries.each do |e|
          zip_file_path = path == '' ? e : File.join(path, e)
          disk_file_path = File.join(@input_dir, zip_file_path)
          puts 'Deflating ' + disk_file_path + '...' unless @quiet
          if File.directory?(disk_file_path)
            io.mkdir(zip_file_path)
            subdir = Dir.entries(disk_file_path)
            subdir.delete('.')
            subdir.delete('..')
            write_entries(subdir, zip_file_path, io)
          else
            io.get_output_stream(zip_file_path) { |f| f.print(File.open(disk_file_path, 'rb').read())}
          end
        end
      end
    end
  end
end