require '../domain/stage'
require_relative '../domain/stage'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module StageAccessor

      def init_file(overwrite = false)
        raise StandardError, 'stage already exists' if !overwrite && File.exist?(STAGE_PATH)
        File.new(STAGE_PATH)
      end

      def remove_file
        File.delete(STAGE_PTH)
      end

      def load_stage
        stg = Kron::Domain::Stage.new
        Zlib::Inflate.inflate(File.read(STAGE_PATH)).each_line do |line|
          stg.put(line.chop.split(" "))
        end
        stg
      end

      def sync_stage(stg)
        f = File.open(STAGE_PATH, "w")
        line = ""
        stg.each_item do |item|
          line += item + "\n"
        end
        f.syswrite(Zlib::Deflate.deflate(line))
        f.close
      end
    end
  end
end