module Kron
  module Domain
    class Stage
      attr_accessor :added_files
      def initialize
       @added_files = []
       end

      def in_stage?(path)
        @added_files.one?(path)
      end

      def stage_empty?
        @added_files.empty?
      end

      def each_stage(&blk)
        @added_files.each do |e|
          yield e
        end
      end

      def put(path)
        @added_files<<path unless in_stage?(path)
      end

    end
  end
end