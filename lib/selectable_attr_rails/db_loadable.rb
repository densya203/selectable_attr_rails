module SelectableAttrRails
  module DbLoadable
    # :when には :first_time (既定) / :everytime / :never を指定します。
    #   :first_time … 最初にエントリを参照したときだけ DB から読み込みます
    #   :everytime  … エントリを参照する度に DB から読み込みます
    #   :never      … DB からは読み込みません
    def update_by(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options = {:when => :first_time}.update(options)
      @sql_to_update = block_given? ? block : args.first
      @update_timing = options[:when]
      @entries_updated = false
      self.extend(InstanceMethods) unless respond_to?(:update_entries)
    end

    # DB から取得した名称を entry#name より優先させるためのモジュールです。
    # entry の特異クラスに prepend するので、何度適用しても安全です。
    module Entry
      if defined?(I18n)
        def name_from_db
          @names_from_db ||= {}
          @names_from_db[I18n.locale.to_s]
        end

        def name_from_db=(value)
          @names_from_db ||= {}
          @names_from_db[I18n.locale.to_s] = value
        end
      else
        attr_accessor :name_from_db
      end

      def name
        name_from_db || super
      end

      def self.apply_to(entry)
        entry.singleton_class.prepend(self)
        entry
      end
    end

    module InstanceMethods
      def entries
        update_entries if must_be_updated?
        @entries
      end

      def must_be_updated?
        case @update_timing
        when :never then false
        when :everytime then true
        else !@entries_updated # :first_time
        end
      end

      def update_entries
        unless @original_entries
          @original_entries = @entries.dup
          @original_entries.each{|entry| Entry.apply_to(entry)}
        end

        records =
          if @sql_to_update.respond_to?(:call)
            @sql_to_update.call
          else
            sql = @sql_to_update.gsub(/\:locale/, I18n.locale.to_s.inspect)
            ActiveRecord::Base.connection_pool.with_connection do |connection|
              connection.select_rows(sql)
            end
          end

        new_entries = []
        records.each do |r|
          if entry = @original_entries.detect{|entry| entry.id == r.first}
            entry.name_from_db = r.last unless r.last.blank?
            new_entries << entry
          else
            entry = SelectableAttr::AkmEnum::Entry.new(self, r.first, "entry_#{r.first}".to_sym, r.last)
            Entry.apply_to(entry)
            entry.name_from_db = r.last
            new_entries << entry
          end
        end
        @original_entries.each do |entry|
          unless new_entries.include?(entry)
            entry.name_from_db = nil
            new_entries << entry if entry.defined_in_code
          end
        end
        @entries_updated = true
        @entries = new_entries
      end
    end

  end
end
