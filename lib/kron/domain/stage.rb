module Kron
  module Domain
    class Stage
      attr_accessor :added_files
      def initialize
       @added_files = []
       end

      def clear_stage
        @added_files.clear
      end

      def in_stage?(path)
        @added_files.one?(path)
      end

      def stage_empty?
        @added_files.empty?
      end

      def each_stage
        raise NotImplementedError
      end

      def check_valid(file_path)
      end

      def change_stage(file,&blk)
        if type(file) == kind_of?('Array')
          file.each{|f| blk.call(f) unless in_stage?(f)
          }
        elsif type(file).kind_of?('String')
          #check whether file is valid?
          blk.call(file) unless in_stage?(file)
        else
          raise TypeError
        end
      end

      def add_to_stage(file, *otherfiles)
        change_stage(file){|f| @added_files.push(f)}
        if otherfiles
          change_stage(otherfiles){|f| @added_files.push(f)}
        end
      end

      def remove_from_stage(file, *otherfiles)
        change_stage(file){|f| @added_files.remove(f)}
        if otherfiles
          change_stage(otherfiles){|f| @added_files.remove(f)}
        end
      end
    end
  end
end