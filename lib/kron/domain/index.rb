module Kron
  module Domain
    class Index
      # map<filename, [sha-1, mt, ct, ...]>
      attr_accessor :tracked_files

      def initialize
        @tracked_files = []
      end

      def in_index?(path)
        @tracked_files.one?(path)
      end

      def index_empty?
        @tracked_files.empty?
      end

      def each_index(&blk)
        @tracked_files.each do |e|
          yield e
        end
      end

      def put(path)
        @tracked_files.push(path) if in_index?(path)
      end

    end
  end
end