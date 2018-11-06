require 'digest'

module Kron
  module Domain
    class Manifest
      attr_reader :rev_id

      def initialize(rev_id)
        @rev_id = rev_id
        @items = {}
      end

      def put(param)
        if param.is_a? String
          file_path = param
          @items[file_path] = [
            Digest::SHA1.file(file_path).hexdigest,
            File.size(file_path),
            File.ctime(file_path).to_i,
            File.mtime(file_path).to_i
          ]
        else
          @items[param[0]] = param.drop(1)
        end
      end

      def each_pair(&blk)
        @items.each_pair(&blk)
      end

      def [](key)
        @items[key]
      end

      # Dir.glob('../**/*') { |f| p f }
    end
  end
end