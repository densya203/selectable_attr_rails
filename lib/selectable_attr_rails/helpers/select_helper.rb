module SelectableAttrRails::Helpers
  module SelectHelper
    # ActionView::Base に prepend して select を拡張します。
    # choices を省略して呼び出された場合だけ selectable_attr の定義から
    # 選択肢を組み立て、それ以外は Rails 本来の select に処理を委ねます。
    module Base
      def select(object_name, method, *args, &block)
        if args.length > 3
          raise ArgumentError, "argument must be " <<
            "(object, method, choices, options = {}, html_options = {}) or " <<
            "(object, method, options = {}, html_options = {})"
        end
        # choices が渡されている場合は Rails 本来の select
        return super if args.length == 3
        return super if args.first.is_a?(Array)

        options, html_options = *args
        options = enum_select_options(options, object_name, method)
        object, base_name = options[:object], options[:base_name]
        if object.respond_to?("#{base_name}_hash_array")
          multi_enum_select(object_name, method, options, html_options, &block)
        elsif object.class.respond_to?("#{base_name}_hash_array")
          single_enum_select(object_name, method, options, html_options, &block)
        else
          raise ArgumentError,
            "#{object.class} has no selectable_attr for #{method.inspect}"
        end
      end

      def single_enum_select(object_name, method, options = nil, html_options = nil, &block)
        options = enum_select_options(options, object_name, method)
        base_name = options.delete(:base_name)
        entry_hash_array = options.delete(:entry_hash_array) ||
          options[:object].class.send("#{base_name}_hash_array")
        container = entry_hash_array.map{|hash| [hash[:name].to_s, hash[:id]]}
        select(object_name, method, container, options, html_options || {}, &block)
      end

      def multi_enum_select(object_name, method, options = nil, html_options = nil, &block)
        html_options = {:size => 5, :multiple => 'multiple'}.update(html_options || {})
        options = enum_select_options(options, object_name, method)
        # :object は Rails 側で選択状態を判定するために残しておきます
        object = options[:object]
        base_name = options.delete(:base_name)
        entry_hash_array = options.delete(:entry_hash_array) ||
          object.send("#{base_name}_hash_array")
        container = entry_hash_array.map{|hash| [hash[:name].to_s, hash[:id].to_s]}
        # 複数選択の値は xxx_ids に出し入れします
        select(object_name, "#{base_name}_ids", container, options, html_options, &block)
      end

      # 呼び出し元から渡されたハッシュを壊さないように複製してから補完します。
      def enum_select_options(options, object_name, method)
        result = (options || {}).dup
        result[:object] ||= instance_variable_get("@#{object_name}")
        if result[:object].nil?
          raise ArgumentError,
            "object not found for #{object_name.inspect}. " <<
            "Set :object option or assign @#{object_name}."
        end
        result[:base_name] ||= result[:object].class.enum_base_name(method.to_s)
        result
      end
    end

    module FormBuilder
      def select(method, *args, &block)
        options = args.first.is_a?(Array) ? (args[1] ||= {}) : (args[0] ||= {})
        options = options.dup
        object = options.delete(:object) || @object ||
          @template.instance_variable_get("@#{@object_name}")
        options[:object] = object if object
        args[args.first.is_a?(Array) ? 1 : 0] = options
        @template.select(@object_name, method, *args, &block)
      end
    end
  end
end
