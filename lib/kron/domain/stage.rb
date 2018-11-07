module Kron
  module Domain
    class Stage
      attr_accessor :added_files
      def initialize
      @added_files = {}
      end


      def in_stage?(path)
        @added_files.keys.one?(path)
      end

      def stage_empty?
        @added_files.empty?
      end

      def each_stage(&blk)
        @added_files.keys.each do |k|
          yield added_files[k],k
        end
      end

      def put(path, head)
        #head : M, A, D
        @added_files[path] = head unless in_stage?(path)
      end

    end
  end
end

# stage = Kron::Domain::Stage.new
# stage.added_files = {"a.txt"=>"A","b.txt"=>"M"}

# p stage.each_stage{|k,y| p k,y}

# p stage.each_stage{|k,y| p k,y}

