if defined?(I18n)
  require File.expand_path('spec_helper', File.dirname(__FILE__))

  describe SelectableAttr::AkmEnum do

    before(:each) do
      I18n.backend = I18n::Backend::Simple.new
      I18n.backend.store_translations :en, 'selectable_attrs' => {'enum1' => {
          'entry1' => 'entry one',
          'entry2' => 'entry two',
          'entry3' => 'entry three'
        } }
      I18n.backend.store_translations :ja, 'selectable_attrs' => {'enum1' => {
          'entry1' => 'エントリ壱',
          'entry2' => 'エントリ弐',
          'entry3' => 'エントリ参'
        } }
      I18n.config.available_locales = [:ja, :en]
      I18n.default_locale = :ja
    end

    AkmEnum1 = SelectableAttr::AkmEnum.new do
      i18n_scope(:selectable_attrs, :enum1)
      entry 1, :entry1, "エントリ1"
      entry 2, :entry2, "エントリ2"
      entry 3, :entry3, "エントリ3"
    end

    it 'test_enum1_i18n' do
      I18n.locale = :ja
      expect(AkmEnum1.name_by_key(:entry1)).to eq("エントリ壱")
      expect(AkmEnum1.name_by_key(:entry2)).to eq("エントリ弐")
      expect(AkmEnum1.name_by_key(:entry3)).to eq("エントリ参")
      expect(AkmEnum1.names).to eq(["エントリ壱", "エントリ弐", "エントリ参"])

      I18n.locale = :en
      expect(AkmEnum1.name_by_key(:entry1)).to eq("entry one")
      expect(AkmEnum1.name_by_key(:entry2)).to eq("entry two")
      expect(AkmEnum1.name_by_key(:entry3)).to eq("entry three")
      expect(AkmEnum1.names).to eq(["entry one", "entry two", "entry three"])
    end

    class AkmEnumBase
      include ::SelectableAttr::Base
    end

    class SelectableAttrMock1 < AkmEnumBase
      selectable_attr :attr1, :default => 2 do
        i18n_scope(:selectable_attrs, :enum1)
        entry 1, :entry1, "エントリ1"
        entry 2, :entry2, "エントリ2"
        entry 3, :entry3, "エントリ3"
      end
    end

    it 'test_attr1_i18n' do
      I18n.locale = :ja
      expect(SelectableAttrMock1.attr1_name_by_key(:entry1)).to eq("エントリ壱")
      expect(SelectableAttrMock1.attr1_name_by_key(:entry2)).to eq("エントリ弐")
      expect(SelectableAttrMock1.attr1_name_by_key(:entry3)).to eq("エントリ参")
      expect(SelectableAttrMock1.attr1_options).to eq([["エントリ壱",1], ["エントリ弐",2], ["エントリ参",3]])

      I18n.locale = :en
      expect(SelectableAttrMock1.attr1_name_by_key(:entry1)).to eq("entry one")
      expect(SelectableAttrMock1.attr1_name_by_key(:entry2)).to eq("entry two")
      expect(SelectableAttrMock1.attr1_name_by_key(:entry3)).to eq("entry three")
      expect(SelectableAttrMock1.attr1_options).to eq([["entry one",1], ["entry two",2], ["entry three",3]])
    end

    class SelectableAttrMock2 < AkmEnumBase
      selectable_attr :enum1, :default => 2 do
        i18n_scope(:selectable_attrs, :enum1)
        entry 1, :entry1, "エントリ1"
        entry 2, :entry2, "エントリ2"
        entry 3, :entry3, "エントリ3"
      end
    end

    it 'test_enum1_i18n' do
      I18n.locale = :ja
      expect(SelectableAttrMock2.enum1_name_by_key(:entry1)).to eq("エントリ壱")
      expect(SelectableAttrMock2.enum1_name_by_key(:entry2)).to eq("エントリ弐")
      expect(SelectableAttrMock2.enum1_name_by_key(:entry3)).to eq("エントリ参")
      expect(SelectableAttrMock2.enum1_options).to eq([["エントリ壱",1], ["エントリ弐",2], ["エントリ参",3]])

      I18n.locale = :en
      expect(SelectableAttrMock2.enum1_name_by_key(:entry1)).to eq("entry one")
      expect(SelectableAttrMock2.enum1_name_by_key(:entry2)).to eq("entry two")
      expect(SelectableAttrMock2.enum1_name_by_key(:entry3)).to eq("entry three")
      expect(SelectableAttrMock2.enum1_options).to eq([["entry one",1], ["entry two",2], ["entry three",3]])
    end

    # i18n用のlocaleカラムを持つselectable_attrのエントリ名をDB上に保持するためのモデル
    class I18nItemMaster < ActiveRecord::Base
    end

    # selectable_attrを使った場合その3
    # アクセス時に毎回アクセス時にDBから項目名を取得します。
    # 対象となる項目名はi18n対応している名称です
    class ProductWithI18nDB1 < ActiveRecord::Base
      self.table_name = 'products'
      selectable_attr :product_type_cd do
        # update_byメソッドには、エントリのidと名称を返すSELECT文を指定する代わりに、
        # エントリのidと名称の配列の配列を返すブロックを指定することも可能です。
        update_by(:when => :everytime) do
          records = I18nItemMaster.where("category_name = 'product_type_cd' and locale = ? ", I18n.locale.to_s).order("item_no")
          records.map{|r| [r.item_cd, r.name]}
        end
        entry '01', :book, '書籍', :discount => 0.8
        entry '02', :dvd, 'DVD', :discount => 0.2
        entry '03', :cd, 'CD', :discount => 0.5
        entry '09', :other, 'その他', :discount => 1
      end

    end

    it "test_update_entry_name_with_i18n" do
      I18n.locale = :ja
      # DBに全くデータがなくてもコードで記述してあるエントリは存在します。
      I18nItemMaster.where("category_name = 'product_type_cd'").delete_all
      expect(ProductWithI18nDB1.product_type_entries.length).to      eq(4)
      expect(ProductWithI18nDB1.product_type_name_by_key(:book)).to  eq('書籍')
      expect(ProductWithI18nDB1.product_type_name_by_key(:dvd)).to   eq('DVD')
      expect(ProductWithI18nDB1.product_type_name_by_key(:cd)).to    eq('CD')
      expect(ProductWithI18nDB1.product_type_name_by_key(:other)).to eq('その他')

      expect(ProductWithI18nDB1.product_type_hash_array).to eq([
        {:id => '01', :key => :book, :name => '書籍', :discount => 0.8},
        {:id => '02', :key => :dvd, :name => 'DVD', :discount => 0.2},
        {:id => '03', :key => :cd, :name => 'CD', :discount => 0.5},
        {:id => '09', :key => :other, :name => 'その他', :discount => 1},
      ])

      # DBからエントリの名称を動的に変更できます
      item_book = I18nItemMaster.create(:locale => :ja, :category_name => 'product_type_cd', :item_no => 1, :item_cd => '01', :name => '本')
      expect(ProductWithI18nDB1.product_type_entries.length).to eq(4)
      expect(ProductWithI18nDB1.product_type_name_by_key(:book)).to eq('本')
      expect(ProductWithI18nDB1.product_type_name_by_key(:dvd)).to eq('DVD')
      expect(ProductWithI18nDB1.product_type_name_by_key(:cd)).to eq('CD')
      expect(ProductWithI18nDB1.product_type_name_by_key(:other)).to eq('その他')
      expect(ProductWithI18nDB1.product_type_options).to eq([['本', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']])

      expect(ProductWithI18nDB1.product_type_hash_array).to eq([
        {:id => '01', :key => :book, :name => '本', :discount => 0.8},
        {:id => '02', :key => :dvd, :name => 'DVD', :discount => 0.2},
        {:id => '03', :key => :cd, :name => 'CD', :discount => 0.5},
        {:id => '09', :key => :other, :name => 'その他', :discount => 1},
      ])

      # DBからエントリの並び順を動的に変更できます
      item_book.item_no = 4;
      item_book.save!
      item_other = I18nItemMaster.create(:locale => :ja, :category_name => 'product_type_cd', :item_no => 1, :item_cd => '09', :name => 'その他')
      item_dvd = I18nItemMaster.create(:locale => :ja, :category_name => 'product_type_cd', :item_no => 2, :item_cd => '02') # nameは指定しなかったらデフォルトが使われます。
      item_cd = I18nItemMaster.create(:locale => :ja, :category_name => 'product_type_cd', :item_no => 3, :item_cd => '03') # nameは指定しなかったらデフォルトが使われます。
      expect(ProductWithI18nDB1.product_type_options).to eq([['その他', '09'], ['DVD', '02'], ['CD', '03'], ['本', '01']])

      # DBからエントリを動的に追加することも可能です。
      item_toys = I18nItemMaster.create(:locale => :ja, :category_name => 'product_type_cd', :item_no => 5, :item_cd => '04', :name => 'おもちゃ')
      expect(ProductWithI18nDB1.product_type_options).to eq([['その他', '09'], ['DVD', '02'], ['CD', '03'], ['本', '01'], ['おもちゃ', '04']])
      expect(ProductWithI18nDB1.product_type_key_by_id('04')).to eq(:entry_04)

      expect(ProductWithI18nDB1.product_type_hash_array).to eq([
        {:id => '09', :key => :other, :name => 'その他', :discount => 1},
        {:id => '02', :key => :dvd, :name => 'DVD', :discount => 0.2},
        {:id => '03', :key => :cd, :name => 'CD', :discount => 0.5},
        {:id => '01', :key => :book, :name => '本', :discount => 0.8},
        {:id => '04', :key => :entry_04, :name => 'おもちゃ'}
      ])


      # 英語名を登録
      item_book = I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 4, :item_cd => '01', :name => 'Book')
      item_other = I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 1, :item_cd => '09', :name => 'Others')
      item_dvd = I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 2, :item_cd => '02', :name => 'DVD')
      item_cd = I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 3, :item_cd => '03', :name => 'CD')
      item_toys = I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 5, :item_cd => '04', :name => 'Toy')

      # 英語名が登録されていてもI18n.localeが変わらなければ、日本語のまま
      expect(ProductWithI18nDB1.product_type_options).to eq([['その他', '09'], ['DVD', '02'], ['CD', '03'], ['本', '01'], ['おもちゃ', '04']])
      expect(ProductWithI18nDB1.product_type_key_by_id('04')).to eq(:entry_04)

      expect(ProductWithI18nDB1.product_type_hash_array).to eq([
        {:id => '09', :key => :other, :name => 'その他', :discount => 1},
        {:id => '02', :key => :dvd, :name => 'DVD', :discount => 0.2},
        {:id => '03', :key => :cd, :name => 'CD', :discount => 0.5},
        {:id => '01', :key => :book, :name => '本', :discount => 0.8},
        {:id => '04', :key => :entry_04, :name => 'おもちゃ'}
      ])

      # I18n.localeを変更すると取得できるエントリの名称も変わります
      I18n.locale = :en
      expect(ProductWithI18nDB1.product_type_options).to eq([['Others', '09'], ['DVD', '02'], ['CD', '03'], ['Book', '01'], ['Toy', '04']])
      expect(ProductWithI18nDB1.product_type_key_by_id('04')).to eq(:entry_04)

      expect(ProductWithI18nDB1.product_type_hash_array).to eq([
        {:id => '09', :key => :other, :name => 'Others', :discount => 1},
        {:id => '02', :key => :dvd, :name => 'DVD', :discount => 0.2},
        {:id => '03', :key => :cd, :name => 'CD', :discount => 0.5},
        {:id => '01', :key => :book, :name => 'Book', :discount => 0.8},
        {:id => '04', :key => :entry_04, :name => 'Toy'}
      ])

      I18n.locale = :ja
      expect(ProductWithI18nDB1.product_type_options).to eq([['その他', '09'], ['DVD', '02'], ['CD', '03'], ['本', '01'], ['おもちゃ', '04']])
      expect(ProductWithI18nDB1.product_type_key_by_id('04')).to eq(:entry_04)

      I18n.locale = :en
      expect(ProductWithI18nDB1.product_type_options).to eq([['Others', '09'], ['DVD', '02'], ['CD', '03'], ['Book', '01'], ['Toy', '04']])
      expect(ProductWithI18nDB1.product_type_key_by_id('04')).to eq(:entry_04)

      # DBからレコードを削除してもコードで定義したentryは削除されません。
      # 順番はDBからの取得順で並び替えられたものの後になります
      item_dvd.destroy
      expect(ProductWithI18nDB1.product_type_options).to eq([['Others', '09'], ['CD', '03'], ['Book', '01'], ['Toy', '04'], ['DVD', '02']])

      # DB上で追加したレコードを削除すると、エントリも削除されます
      item_toys.destroy
      expect(ProductWithI18nDB1.product_type_options).to eq([['Others', '09'], ['CD', '03'], ['Book', '01'], ['DVD', '02']])

      # 名称を指定していたDBのレコードを削除したら元に戻ります。
      item_book.destroy
      expect(ProductWithI18nDB1.product_type_options).to eq([['Others', '09'], ['CD', '03'], ['書籍', '01'], ['DVD', '02']])

      # エントリに該当するレコードを全部削除したら、元に戻ります。
      I18nItemMaster.where("category_name = 'product_type_cd'").delete_all
      expect(ProductWithI18nDB1.product_type_options).to eq([['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']])
    end

    it 'test_i18n_export' do
      io = StringIO.new
      SelectableAttrRails.logger = Logger.new(io)

      I18nItemMaster.where("category_name = 'product_type_cd'").delete_all

      I18n.locale = :ja
      actual = SelectableAttr::AkmEnum.i18n_export
      expect(actual.keys).to eq(['selectable_attrs'])
      expect(actual['selectable_attrs'].keys.include?('enum1')).to eq(true)
      expect(actual['selectable_attrs']['enum1']).to eq(
        {'entry1'=>"エントリ壱",
         'entry2'=>"エントリ弐",
         'entry3'=>"エントリ参"}
      )

      expect(actual['selectable_attrs']['ProductWithI18nDB1']).to eq(
        {'product_type_cd'=>
          {'book'=>"書籍", 'dvd'=>"DVD", 'cd'=>"CD", 'other'=>"その他"}}
      )

      I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 1, :item_cd => '09', :name => 'Others')
      I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 2, :item_cd => '02', :name => 'DVD')
      I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 3, :item_cd => '03', :name => 'CD')
      I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 4, :item_cd => '01', :name => 'Book')
      I18nItemMaster.create(:locale => :en, :category_name => 'product_type_cd', :item_no => 5, :item_cd => '04', :name => 'Toy')

      I18n.locale = :en
      actual = SelectableAttr::AkmEnum.i18n_export
      expect(actual.keys).to eq(['selectable_attrs'])
      expect(actual['selectable_attrs'].keys.include?('enum1')).to eq(true)
      expect(actual['selectable_attrs']['enum1']).to eq(
        {'entry1'=>"entry one",
         'entry2'=>"entry two",
         'entry3'=>"entry three"}
      )
      expect(actual['selectable_attrs'].keys).to include('ProductWithI18nDB1')
      expect(actual['selectable_attrs']['ProductWithI18nDB1']).to eq(
        {'product_type_cd'=>
          {'book'=>"Book", 'dvd'=>"DVD", 'cd'=>"CD", 'other'=>"Others", 'entry_04'=>"Toy"}}
      )
    end

    AkmEnum2 = SelectableAttr::AkmEnum.new do
      entry 1, :entry1, "縁鳥1"
      entry 2, :entry2, "縁鳥2"
      entry 3, :entry3, "縁鳥3"
    end

    it "i18n_scope missing" do
      io = StringIO.new
      SelectableAttrRails.logger = Logger.new(io)
      actual = SelectableAttr::AkmEnum.i18n_export([AkmEnum2])
      expect(actual.inspect).not_to match(/縁鳥/)
      io.rewind
      expect(io.readline).to match(/no i18n_scope of/)
    end
  end
else
  $stderr.puts "WARNING! i18n test skipeed because I18n not found"
end
