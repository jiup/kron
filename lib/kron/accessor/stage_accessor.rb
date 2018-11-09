require_relative '../../kron/constant'
require_relative '../domain/stage'
require 'zlib'
require 'fileutils'

module Kron
  module Accessor
    module StageAccessor
      def init_stage
        File.new(STAGE_PATH, 'w')
        FileUtils.mkdir_p STAGE_DIR
      end

      def remove_stage
        File.delete(STAGE_PATH) if File.exist?(STAGE_PATH)
        FileUtils.rm_rf STAGE_DIR if Dir.exist?(STAGE_DIR)
      end

      def load_stage
        File.new(STAGE_PATH, 'w') unless File.exist? STAGE_PATH
        FileUtils.mkdir_p STAGE_DIR unless Dir.exist? STAGE_DIR
        stage = Kron::Domain::Stage.new
        return stage unless File.size(STAGE_PATH) > 0

        Zlib::Inflate.inflate(File.read(STAGE_PATH)).each_line do |line|
          case line[0..1]
          when 'a:'
            line[2..-1].chop.split('&').each { |e| stage.to_add << e }
          when 'm:'
            line[2..-1].chop.split('&').each { |e| stage.to_modify << e }
          when 'd:'
            line[2..-1].chop.split('&').each { |e| stage.to_delete << e }
          else
            raise IOError, 'Stage file was broken (invalid line)'
          end
        end
        stage
      end

      def sync_stage(stage)
        f = File.open(STAGE_PATH, 'w')
        buffer = StringIO.new
        buffer.puts "a:#{stage.to_add.map { |e| e }.join('&')}"
        buffer.puts "m:#{stage.to_modify.map { |e| e }.join('&')}"
        buffer.puts "d:#{stage.to_delete.map { |e| e }.join('&')}"
        f.write(Zlib::Deflate.deflate(buffer.string))
        f.close
      end

      # def load_stage
      #   init_stage_dir(true) unless File.exist?(STAGE_PATH)
      #
      #   stg = Kron::Domain::Stage.new
      #   heads = %w[@added @modified @removed]
      #   if File.exist? STAGE_PATH
      #     return stg unless File.size(STAGE_PATH) > 0
      #
      #     Zlib::Inflate.inflate(File.read(STAGE_PATH)).each_line do |line|
      #     line.chop.split('&').each do |kv|
      #     k, v = kv.split('=')
      #     stg.put(k, heads.shift)
      #     end
      #   end
      #     stg
      #   end
      # end

      # def sync_stage(stg)
      #   f = File.open(STAGE_PATH, 'w')
      #   heads = %w[@added @modified @removed]
      #   buffer = StringIO.new
      #   heads.each do |var|
      #     buffer << "#{stg.instance_variable_get(var).map { |k, v| "#{k}=#{v}" }.join('&')}\n"
      #   end
      #   f.write(Zlib::Deflate.deflate(buffer.string))
      #   f.close
      # end
    end
  end
end