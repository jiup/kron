require_relative '../../kron/constant'
require_relative '../domain/stage'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module StageAccessor

      def init_stage_dir(overwrite = false)
        raise StandardError, 'stage already exists' if !overwrite && File.exist?(STAGE_PATH)

        File.new(STAGE_PATH, 'w')
        FileUtils.mkdir_p STAGE_DIR unless Dir.exist? STAGE_DIR
      end

      def remove_stage_dir
        File.delete(STAGE_PATH) if File.exist?(STAGE_PATH)
        Dir.delete(STAGE_DIR) if Dir.exist? STAGE_DIR
      end

      def load_stage
        init_stage_dir(true) unless File.exist?(STAGE_PATH)

        stg = Kron::Domain::Stage.new
        heads = %w[@added @modified @removed]
        if File.exist? STAGE_PATH
          return stg unless File.size(STAGE_PATH) > 0

          Zlib::Inflate.inflate(File.read(STAGE_PATH)).each_line do |line|
          line.chop.split('&').each do |kv|
          k, v = kv.split('=')
          stg.put(k, heads.shift)
          end
        end
          stg
        end
      end

      def sync_stage(stg)
        f = File.open(STAGE_PATH, 'w')
        heads = %w[@added @modified @removed]
        buffer = StringIO.new
        heads.each do |var|
          buffer << "#{stg.instance_variable_get(var).map { |k, v| "#{k}=#{v}" }.join('&')}\n"
        end
        f.write(Zlib::Deflate.deflate(buffer.string))
        f.close
      end
    end
  end
end