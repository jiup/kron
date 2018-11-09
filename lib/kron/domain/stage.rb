require 'digest'

module Kron
  module Domain
    class Stage
      attr_accessor :added, :modified, :removed

      def initialize
      @added = {}
      @modified = {}
      @removed = {}
      end

      def get(arg, *args)
        args ||= %w[added modified removed] unless args
        args.each do |ivar|
          file_hash = instance_variable_get(ivar).fetch(arg, nil)
          return [arg, file_hash] if file_hash
        end
        nil
      end

      def put(path, head)
        # head : @added, @modified, @removed
        return nil unless %w[@added @modified @removed].one?(head)

        path = File.expand_path(path)
        h = Digest::SHA1.file(path).hexdigest
        instance_variable_set(head, path => h)
      end

      def remove(path, *head)
        path = File.expand_path(path)

        head = %w[@added @modified @removed] if head == []
        head.each do |ivar|
          file_hash = instance_variable_get(ivar).fetch(path, nil)
          return instance_variable_get(ivar).delete(path) if file_hash
        end
      end
    end
  end
end

