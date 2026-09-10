require 'selectable_attr_rails/validatable'

module SelectableAttrRails
  module Validatable
    module Base
      def self.included(mod)
        # SelectableAttr::Base::ClassMethods#define_enum を包みます (prepend は冪等)
        mod.singleton_class.prepend(ClassMethods)
      end

      module ClassMethods
        def define_enum(context)
          super
          enum = context[:enum]
          return unless enum.respond_to?(:validates_format_options)
          return unless (options = enum.validates_format_options)

          # enum が保持しているハッシュを壊さないように複製してから使います
          options = options.dup
          # 前方後方をアンカーで固定しないと "X01Y" のような値も通ってしまいます
          options[:with] = Regexp.union(
            *enum.entries.map{|entry| /\A#{Regexp.escape(entry.id.to_s)}\z/})
          entry_format = options.delete(:entry_format) || '#{entry.name}'
          entries = enum.entries.map{|entry| instance_eval("\"#{entry_format}\"")}.join(', ')
          message = options.delete(:message) || 'is invalid, must be one of #{entries}'
          options[:message] = instance_eval("\"#{message}\"")
          validates_format_of(context[:attr], options)
        end
      end
    end
  end
end
