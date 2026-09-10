module SelectableAttrRails::Helpers
  class AbstractSelectionBuilder
    attr_reader :entry_hash
    attr_reader :entry_hash_array

    def initialize(object, object_name, method, options, template)
      @object, @object_name, @method = object, object_name, method
      if @object.nil?
        raise ArgumentError,
          "object not found for #{object_name.inspect}. " <<
          "Set :object option or assign @#{object_name}."
      end
      @base_name = @object.class.enum_base_name(method.to_s)
      @template = template
      @entry_hash = nil
      # 呼び出し元のハッシュを壊さないように複製してから使います
      @options = (options || {}).dup
      @entry_hash_array = @options.delete(:entry_hash_array)
    end

    def enum_hash_array_from_object
      @object.send("#{@base_name}_hash_array")
    end

    def enum_hash_array_from_class
      @object.class.send("#{@base_name}_hash_array")
    end

    def add_class_name(options, class_name)
      options = options.stringify_keys
      current = options['class'].to_s
      options['class'] = current.empty? ? class_name.to_s : "#{current} #{class_name}"
      options
    end

    # dest と options_array をマージした新しいハッシュを返します。
    # :class だけは上書きではなく追記します。
    def update_options(dest, *options_array)
      result = (dest || {}).dup
      options_array.each do |options|
        next unless options
        options = options.dup
        if class_name = options.delete(:class) || options.delete('class')
          result = add_class_name(result, class_name)
        end
        result.update(options)
      end
      result
    end

  end
end
