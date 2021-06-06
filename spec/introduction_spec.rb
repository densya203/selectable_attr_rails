require File.expand_path('spec_helper', File.dirname(__FILE__))

describe SelectableAttr do

  def assert_product_discount(klass)
    # productsテーブルのデータから安売り用の価格は
    # product_type_cd毎に決められた割合をpriceにかけて求めます。
    p1 = klass.new(:name => '実践Rails', :product_type_cd => '01', :price => 3000)
    expect(p1.discount_price).to eq(2400)
    p2 = klass.new(:name => '薔薇の名前', :product_type_cd => '02', :price => 1500)
    expect(p2.discount_price).to eq(300)
    p3 = klass.new(:name => '未来派野郎', :product_type_cd => '03', :price => 3000)
    expect(p3.discount_price).to eq(1500)
  end

  # 定数をガンガン定義した場合
  # 大文字が多くて読みにくいし、関連するデータ(ここではDISCOUNT)が増える毎に定数も増えていきます。
  class LegacyProduct1 < ActiveRecord::Base
    self.table_name = 'products'

    PRODUCT_TYPE_BOOK = '01'
    PRODUCT_TYPE_DVD = '02'
    PRODUCT_TYPE_CD = '03'
    PRODUCT_TYPE_OTHER = '09'

    PRODUCT_TYPE_OPTIONS = [
      ['書籍', PRODUCT_TYPE_BOOK],
      ['DVD', PRODUCT_TYPE_DVD],
      ['CD', PRODUCT_TYPE_CD],
      ['その他', PRODUCT_TYPE_OTHER]
    ]

    DISCOUNT = {
      PRODUCT_TYPE_BOOK => 0.8,
      PRODUCT_TYPE_DVD => 0.2,
      PRODUCT_TYPE_CD => 0.5,
      PRODUCT_TYPE_OTHER => 1
    }

    def discount_price
      (DISCOUNT[product_type_cd] * price).to_i
    end
  end

  it "test_legacy_product" do
    assert_product_discount(LegacyProduct1)

    # 選択肢を表示するためのデータは以下のように取得できる
    expect(LegacyProduct1::PRODUCT_TYPE_OPTIONS).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )
  end




  # できるだけ定数定義をまとめた場合
  # 結構すっきりするけど、同じことをいろんなモデルで書くかと思うと気が重い。
  class LegacyProduct2 < ActiveRecord::Base
    self.table_name = 'products'

    PRODUCT_TYPE_DEFS = [
      {:id => '01', :name => '書籍', :discount => 0.8},
      {:id => '02', :name => 'DVD', :discount => 0.2},
      {:id => '03', :name => 'CD', :discount => 0.5},
      {:id => '09', :name => 'その他', :discount => 1}
    ]

    PRODUCT_TYPE_OPTIONS = PRODUCT_TYPE_DEFS.map{|t| [t[:name], t[:id]]}
    DISCOUNT = PRODUCT_TYPE_DEFS.inject({}){|dest, t|
      dest[t[:id]] = t[:discount]; dest}

    def discount_price
      (DISCOUNT[product_type_cd] * price).to_i
    end
  end

  it "test_legacy_product" do
    assert_product_discount(LegacyProduct2)

    # 選択肢を表示するためのデータは以下のように取得できる
    expect(LegacyProduct2::PRODUCT_TYPE_OPTIONS).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )
  end

  # selectable_attrを使った場合
  # 定義は一カ所にまとめられて、任意の属性(ここでは:discount)も一緒に書くことができてすっきり〜
  class Product1 < ActiveRecord::Base
    self.table_name = 'products'

    selectable_attr :product_type_cd do
      entry '01', :book, '書籍', :discount => 0.8
      entry '02', :dvd, 'DVD', :discount => 0.2
      entry '03', :cd, 'CD', :discount => 0.5
      entry '09', :other, 'その他', :discount => 1
      validates_format :allow_nil => true, :message => 'は次のいずれかでなければなりません。 #{entries}'
    end

    def discount_price
      (product_type_entry[:discount] * price).to_i
    end
  end

  it "test_product1" do
    assert_product_discount(Product1)
    # 選択肢を表示するためのデータは以下のように取得できる
    expect(Product1.product_type_options).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )
  end


  # selectable_attrが定義するインスタンスメソッドの詳細
  it "test_product_type_instance_methods" do
    p1 = Product1.new
    expect(p1.product_type_cd).to be_nil
    expect(p1.product_type_key).to be_nil
    expect(p1.product_type_name).to be_nil
    # idを変更すると得られるキーも名称も変わります
    p1.product_type_cd = '02'
    expect(p1.product_type_cd).to eq('02')
    expect(p1.product_type_key).to eq(:dvd)
    expect(p1.product_type_name).to eq('DVD')
    # キーを変更すると得られるidも名称も変わります
    p1.product_type_key = :book
    expect(p1.product_type_cd).to eq('01')
    expect(p1.product_type_key).to eq(:book)
    expect(p1.product_type_name).to eq('書籍')
    # id、キー、名称以外の任意の属性は、entryの[]メソッドで取得します。
    p1.product_type_key = :cd
    expect(p1.product_type_entry[:discount]).to eq(0.5)
  end

  # selectable_attrが定義するクラスメソッドの詳細
  it "test_product_type_class_methods" do
    # キーからid、名称を取得できます
    expect(Product1.product_type_id_by_key(:book)).to eq('01')
    expect(Product1.product_type_id_by_key(:dvd)).to eq('02')
    expect(Product1.product_type_id_by_key(:cd)).to eq('03')
    expect(Product1.product_type_id_by_key(:other)).to eq('09')
    expect(Product1.product_type_name_by_key(:book)).to eq('書籍')
    expect(Product1.product_type_name_by_key(:dvd)).to eq('DVD')
    expect(Product1.product_type_name_by_key(:cd)).to eq('CD')
    expect(Product1.product_type_name_by_key(:other)).to eq('その他')
    # 存在しないキーの場合はnilを返します
    expect(Product1.product_type_id_by_key(nil)).to be_nil
    expect(Product1.product_type_name_by_key(nil)).to be_nil
    expect(Product1.product_type_id_by_key(:unexist)).to be_nil
    expect(Product1.product_type_name_by_key(:unexist)).to be_nil

    # idからキー、名称を取得できます
    expect(Product1.product_type_key_by_id('01')).to eq(:book)
    expect(Product1.product_type_key_by_id('02')).to eq(:dvd)
    expect(Product1.product_type_key_by_id('03')).to eq(:cd)
    expect(Product1.product_type_key_by_id('09')).to eq(:other)
    expect(Product1.product_type_name_by_id('01')).to eq('書籍')
    expect(Product1.product_type_name_by_id('02')).to eq('DVD')
    expect(Product1.product_type_name_by_id('03')).to eq('CD')
    expect(Product1.product_type_name_by_id('09')).to eq('その他')
    # 存在しないidの場合はnilを返します
    expect(Product1.product_type_key_by_id(nil)).to be_nil
    expect(Product1.product_type_name_by_id(nil)).to be_nil
    expect(Product1.product_type_key_by_id('99')).to be_nil
    expect(Product1.product_type_name_by_id('99')).to be_nil

    # id、キー、名称の配列を取得できます
    expect(Product1.product_type_ids).to eq(['01', '02', '03', '09'])
    expect(Product1.product_type_keys).to eq([:book, :dvd, :cd, :other])
    expect(Product1.product_type_names).to eq(['書籍', 'DVD', 'CD', 'その他'])
    # 一部のものだけ取得することも可能です。
    expect(Product1.product_type_ids(:cd, :dvd)).to eq(['03', '02' ])
    expect(Product1.product_type_keys('02', '03')).to eq([:dvd, :cd  ])
    expect(Product1.product_type_names('02', '03')).to eq(['DVD', 'CD'])
    expect(Product1.product_type_names(:cd, :dvd)).to eq(['CD', 'DVD'])

    # select_tagなどのoption_tagsを作るための配列なんか一発っす
    expect(Product1.product_type_options).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )
  end

  it "validate with entries" do
    p1 = Product1.new
    expect(p1.product_type_cd).to eq(nil)
    expect(p1.valid?).to eq(true)
    expect(p1.errors.empty?).to eq(true)

    p1.product_type_key = :book
    expect(p1.product_type_cd).to eq('01')
    expect(p1.valid?).to eq(true)
    expect(p1.errors.empty?).to eq(true)

    p1.product_type_cd = 'XX'
    expect(p1.product_type_cd).to eq('XX')
    expect(p1.valid?).to eq(false)
    if ActiveRecord::VERSION::MAJOR <= 2
      expect(p1.errors.on(:product_type_cd)).to eq("は次のいずれかでなければなりません。 書籍, DVD, CD, その他")
    else
      expect(p1.errors[:product_type_cd]).to eq(["は次のいずれかでなければなりません。 書籍, DVD, CD, その他"])
    end
  end

  # selectable_attrのエントリ名をDB上に保持するためのモデル
  class ItemMaster < ActiveRecord::Base
  end

  # selectable_attrを使った場合その２
  # アクセス時に毎回アクセス時にDBから項目名を取得します。
  class ProductWithDB1 < ActiveRecord::Base
    self.table_name = 'products'

    selectable_attr :product_type_cd do
      update_by(
        "select item_cd, name from item_masters where category_name = 'product_type_cd' order by item_no",
        :when => :everytime)
      entry '01', :book, '書籍', :discount => 0.8
      entry '02', :dvd, 'DVD', :discount => 0.2
      entry '03', :cd, 'CD', :discount => 0.5
      entry '09', :other, 'その他', :discount => 1
    end

    def discount_price
      (product_type_entry[:discount] * price).to_i
    end
  end

  it "test_update_entry_name" do
    # DBに全くデータがなくてもコードで記述してあるエントリは存在します。
    ItemMaster.where("category_name = 'product_type_cd'").delete_all
    expect(ProductWithDB1.product_type_entries.length).to eq(4)
    expect(ProductWithDB1.product_type_name_by_key(:book)).to eq('書籍')
    expect(ProductWithDB1.product_type_name_by_key(:dvd)).to eq('DVD')
    expect(ProductWithDB1.product_type_name_by_key(:cd)).to eq('CD')
    expect(ProductWithDB1.product_type_name_by_key(:other)).to eq('その他')

    assert_product_discount(ProductWithDB1)

    # DBからエントリの名称を動的に変更できます
    item_book = ItemMaster.create(:category_name => 'product_type_cd', :item_no => 1, :item_cd => '01', :name => '本')
    expect(ProductWithDB1.product_type_entries.length).to eq(4)
    expect(ProductWithDB1.product_type_name_by_key(:book)).to eq('本')
    expect(ProductWithDB1.product_type_name_by_key(:dvd)).to eq('DVD')
    expect(ProductWithDB1.product_type_name_by_key(:cd)).to eq('CD')
    expect(ProductWithDB1.product_type_name_by_key(:other)).to eq('その他')
    expect(ProductWithDB1.product_type_options).to eq(
      [['本', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )

    # DBからエントリの並び順を動的に変更できます
    item_book.item_no = 4;
    item_book.save!
    item_other = ItemMaster.create(:category_name => 'product_type_cd', :item_no => 1, :item_cd => '09', :name => 'その他')
    item_dvd = ItemMaster.create(:category_name => 'product_type_cd', :item_no => 2, :item_cd => '02') # nameは指定しなかったらデフォルトが使われます。
    item_cd = ItemMaster.create(:category_name => 'product_type_cd', :item_no => 3, :item_cd => '03') # nameは指定しなかったらデフォルトが使われます。
    expect(ProductWithDB1.product_type_options).to eq(
      [['その他', '09'], ['DVD', '02'], ['CD', '03'], ['本', '01']]
    )

    # DBからエントリを動的に追加することも可能です。
    item_toys = ItemMaster.create(:category_name => 'product_type_cd', :item_no => 5, :item_cd => '04', :name => 'おもちゃ')
    expect(ProductWithDB1.product_type_options).to eq(
      [['その他', '09'], ['DVD', '02'], ['CD', '03'], ['本', '01'], ['おもちゃ', '04']]
    )
    expect(ProductWithDB1.product_type_key_by_id('04')).to eq(:entry_04)

    # DBからレコードを削除してもコードで定義したentryは削除されません。
    # 順番はDBからの取得順で並び替えられたものの後になります
    item_dvd.destroy
    expect(ProductWithDB1.product_type_options).to eq(
      [['その他', '09'], ['CD', '03'], ['本', '01'], ['おもちゃ', '04'], ['DVD', '02']]
    )

    # DB上で追加したレコードを削除すると、エントリも削除されます
    item_toys.destroy
    expect(ProductWithDB1.product_type_options).to eq(
      [['その他', '09'], ['CD', '03'], ['本', '01'], ['DVD', '02']]
    )

    # 名称を指定していたDBのレコードを削除したら元に戻ります。
    item_book.destroy
    expect(ProductWithDB1.product_type_options).to eq(
      [['その他', '09'], ['CD', '03'], ['書籍', '01'], ['DVD', '02']]
    )

    # エントリに該当するレコードを全部削除したら、元に戻ります。
    ItemMaster.where("category_name = 'product_type_cd'").delete_all
    expect(ProductWithDB1.product_type_options).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )

    assert_product_discount(ProductWithDB1)
  end




  # Q: product_type_cd の'_cd'はどこにいっちゃったの？
  # A: デフォルトでは、/(_cd$|_code$|_cds$|_codes$)/ を削除したものをbase_nameとして
  #    扱い、それに_keyなどを付加してメソッド名を定義します。もしこのルールを変更したい場合、
  #    selectable_attrを使う前に selectable_attr_name_pattern で新たなルールを指定してください。
  class Product2 < ActiveRecord::Base
    self.table_name = 'products'
    self.selectable_attr_name_pattern = /^product_|_cd$/

    selectable_attr :product_type_cd do
      entry '01', :book, '書籍', :discount => 0.8
      entry '02', :dvd, 'DVD', :discount => 0.2
      entry '03', :cd, 'CD', :discount => 0.5
      entry '09', :other, 'その他', :discount => 1
    end

    def discount_price
      (type_entry[:discount] * price).to_i
    end
  end

  it "test_product2" do
    assert_product_discount(Product2)
    # 選択肢を表示するためのデータは以下のように取得できる
    expect(Product2.type_options).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )

    p2 = Product2.new
    expect(p2.product_type_cd).to be_nil
    expect(p2.type_key).to be_nil
    expect(p2.type_name).to be_nil
    # idを変更すると得られるキーも名称も変わります
    p2.product_type_cd = '02'
    expect(p2.product_type_cd).to eq('02')
    expect(p2.type_key).to eq(:dvd)
    expect(p2.type_name).to eq('DVD')
    # キーを変更すると得られるidも名称も変わります
    p2.type_key = :book
    expect(p2.product_type_cd).to eq('01')
    expect(p2.type_key).to eq(:book)
    expect(p2.type_name).to eq('書籍')
    # id、キー、名称以外の任意の属性は、entryの[]メソッドで取得します。
    p2.type_key = :cd
    expect(p2.type_entry[:discount]).to eq(0.5)

    expect(Product2.type_id_by_key(:book)).to eq('01')
    expect(Product2.type_id_by_key(:dvd)).to eq('02')
    expect(Product2.type_name_by_key(:cd)).to eq('CD')
    expect(Product2.type_name_by_key(:other)).to eq('その他')
    expect(Product2.type_key_by_id('09')).to eq(:other)
    expect(Product2.type_name_by_id('01')).to eq('書籍')
    expect(Product2.type_keys).to eq([:book, :dvd, :cd, :other])
    expect(Product2.type_names).to eq(['書籍', 'DVD', 'CD', 'その他'])
    expect(Product2.type_keys('02', '03')).to eq([:dvd, :cd])
    expect(Product2.type_names(:cd, :dvd)).to eq(['CD', 'DVD'])
  end




  # Q: selectable_attrの呼び出し毎にbase_bname(って言うの？)を指定したいんだけど。
  # A: base_nameオプションを指定してください。
  class Product3 < ActiveRecord::Base
    self.table_name = 'products'

    selectable_attr :product_type_cd, :base_name => 'type' do
      entry '01', :book, '書籍', :discount => 0.8
      entry '02', :dvd, 'DVD', :discount => 0.2
      entry '03', :cd, 'CD', :discount => 0.5
      entry '09', :other, 'その他', :discount => 1
    end

    def discount_price
      (type_entry[:discount] * price).to_i
    end
  end

  it "test_product3" do
    assert_product_discount(Product3)
    # 選択肢を表示するためのデータは以下のように取得できる
    expect(Product3.type_options).to eq(
      [['書籍', '01'], ['DVD', '02'], ['CD', '03'], ['その他', '09']]
    )

    p3 = Product3.new
    expect(p3.product_type_cd).to be_nil
    expect(p3.type_key).to be_nil
    expect(p3.type_name).to be_nil
    # idを変更すると得られるキーも名称も変わります
    p3.product_type_cd = '02'
    expect(p3.product_type_cd).to eq('02')
    expect(p3.type_key).to eq(:dvd)
    expect(p3.type_name).to eq('DVD')
    # キーを変更すると得られるidも名称も変わります
    p3.type_key = :book
    expect(p3.product_type_cd).to eq('01')
    expect(p3.type_key).to eq(:book)
    expect(p3.type_name).to eq('書籍')
    # id、キー、名称以外の任意の属性は、entryの[]メソッドで取得します。
    p3.type_key = :cd
    expect(p3.type_entry[:discount]).to eq(0.5)

    expect(Product3.type_id_by_key(:book)).to eq('01')
    expect(Product3.type_id_by_key(:dvd)).to eq('02')
    expect(Product3.type_name_by_key(:cd)).to eq('CD')
    expect(Product3.type_name_by_key(:other)).to eq('その他')
    expect(Product3.type_key_by_id('09')).to eq(:other)
    expect(Product3.type_name_by_id('01')).to eq('書籍')
    expect(Product3.type_keys).to eq([:book, :dvd, :cd, :other])
    expect(Product3.type_names).to eq(['書籍', 'DVD', 'CD', 'その他'])
    expect(Product3.type_keys('02', '03')).to eq([:dvd, :cd])
    expect(Product3.type_names(:cd, :dvd)).to eq(['CD', 'DVD'])
  end

end

