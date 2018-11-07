module Kron
  module Domain
    class Index
      # map<filename, [sha-1, mt, ct, ...]>
      attr_reader :revid

      def initialize(revid)
        @revid = revid
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
    end
  end
end