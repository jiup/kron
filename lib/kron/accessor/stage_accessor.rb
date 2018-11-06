require '../domain/stage'
require 'base64'
module Kron
  module Accessor
    module StageAccessor
      def load_stage(stage, file, blk)
        # file valid?
        unless File::exist?(file)
          raise IOError
        end
        lines = IO.readlines(file)
        #raise Warning
        stage.clear_stage
        lines.each do |line|
          if blk != nil
            line = blk.call(line)
          end
          stage.add_to_stage(line)
        end
        stage
      end

      def sync_stage(dst,source)
        unless type(dst).kind_of?("Stage") or type(source).kind_of?("Stage")
          raise TypeError
        end
        source.each_stage do |stage|
          dst.add_to_stage(stage) unless dst.in_stage?(stage)
        end
        dst
      end

      def from_stage(file,stage)
        unless File::exist?(file)
          raise Warning
        end
        File.open(file, "w") do |aFile|
          stage.each_stage do |stage|
           #compress line
           aFile.syswrite(stage)
          end
        end
      end

    end
  end
end