require_relative '../../kron/constant'
require_relative '../domain/stage'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module StageAccessor

      def init_file(overwrite = false)
        raise StandardError, 'stage already exists' if !overwrite && File.exist?(STAGE_PATH)
        f = File.new(STAGE_PATH,"w")
        f.close
      end

      def remove_file
        File.delete(STAGE_PATH)
      end

      def load_stage
        stg = Kron::Domain::Stage.new
<<<<<<< HEAD
        if File.exist? STAGE_PATH
=======
          if File.exist? STAGE_PATH
>>>>>>> 985e9edfd326462b049d485637aaf9fa6635c94b
          Zlib::Inflate.inflate(File.read(STAGE_PATH)).each_line do |line|
            params = line.chop.split(":",2)
            stg.put(params[-1],params[0])
          end
        end
        stg
      end

      def sync_stage(stg)
        f = File.open(STAGE_PATH, "w")
        line = ""
        stg.each_stage do |path, head|
          line += head + ":" + path + "\n"
        end
        f.syswrite(Zlib::Deflate.deflate(line))
        f.close
      end
    end
  end
end