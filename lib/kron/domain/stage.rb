require 'digest'
require 'set'

module Kron
  module Domain
    class Stage
      attr_accessor :to_add, :to_modify, :to_delete

      def initialize
        @to_add = Set.new
        @to_modify = Set.new
        @to_delete = Set.new
      end

      def include?(file_path)
        to_add?(file_path) || to_modify?(file_path) || to_delete?(file_path)
      end

      def to_add?(file_path)
        @to_add.include? file_path
      end

      def to_modify?(file_path)
        @to_modify.include? file_path
      end

      def to_delete?(file_path)
        @to_delete.include? file_path
      end

      def remove_all(file_path)
        @to_add.delete file_path
        @to_modify.delete file_path
        @to_add.delete file_path
      end

      # def get(arg, *args)
      #   args ||= %w[added modified removed] unless args
      #   args.each do |ivar|
      #     file_hash = instance_variable_get(ivar).fetch(arg, nil)
      #     return [arg, file_hash] if file_hash
      #   end
      #   nil
      # end

      # def put(path, head)
      #   # head : @added, @modified, @removed
      #   return nil unless %w[@added @modified @removed].one?(head)
      #
      #   path = File.expand_path(path)
      #   h = Digest::SHA1.file(path).hexdigest
      #   instance_variable_set(head, path => h)
      # end

      # def remove(path, *head)
      #   path = File.expand_path(path)
      #
      #   head = %w[@added @modified @removed] if head == []
      #   head.each do |ivar|
      #     file_hash = instance_variable_get(ivar).fetch(path, nil)
      #     return instance_variable_get(ivar).delete(path) if file_hash
      #   end
      # end
    end
  end
end

