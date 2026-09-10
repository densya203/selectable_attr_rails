# -*- coding: utf-8 -*-
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe SelectableAttrRails::DbLoadable do

  class DbLoadableItemMaster < ActiveRecord::Base
    self.table_name = 'item_masters'
  end

  SQL = "select item_cd, name from item_masters " <<
    "where category_name = 'db_loadable' order by item_no"

  def build_enum(options = {})
    SelectableAttr::AkmEnum.new do
      update_by(SQL, options)
      entry '01', :book, '書籍'
      entry '02', :dvd,  'DVD'
    end
  end

  before(:each) do
    DbLoadableItemMaster.where(:category_name => 'db_loadable').delete_all
  end

  describe ':when => :first_time (既定値)' do
    it '最初にエントリを参照したときに DB から読み込みます' do
      DbLoadableItemMaster.create!(:category_name => 'db_loadable',
        :item_no => 1, :item_cd => '01', :name => '本')
      enum = build_enum
      expect(enum.names).to eq(['本', 'DVD'])
    end

    it '2 回目以降は DB を読み直しません' do
      DbLoadableItemMaster.create!(:category_name => 'db_loadable',
        :item_no => 1, :item_cd => '01', :name => '本')
      enum = build_enum
      expect(enum.names).to eq(['本', 'DVD'])
      DbLoadableItemMaster.where(:item_cd => '01').update_all(:name => '書物')
      expect(enum.names).to eq(['本', 'DVD'])
    end
  end

  describe ':when => :everytime' do
    it '参照の度に DB から読み込みます' do
      DbLoadableItemMaster.create!(:category_name => 'db_loadable',
        :item_no => 1, :item_cd => '01', :name => '本')
      enum = build_enum(:when => :everytime)
      expect(enum.names).to eq(['本', 'DVD'])
      DbLoadableItemMaster.where(:item_cd => '01').update_all(:name => '書物')
      expect(enum.names).to eq(['書物', 'DVD'])
    end
  end

  describe ':when => :never' do
    it 'DB を読み込みません' do
      DbLoadableItemMaster.create!(:category_name => 'db_loadable',
        :item_no => 1, :item_cd => '01', :name => '本')
      enum = build_enum(:when => :never)
      expect(enum.names).to eq(['書籍', 'DVD'])
    end
  end

  it 'ブロックを渡した場合も同じように動作します' do
    records = [['01', 'ブロック由来']]
    enum = SelectableAttr::AkmEnum.new do
      update_by(:when => :everytime) { records }
      entry '01', :book, '書籍'
    end
    expect(enum.names).to eq(['ブロック由来'])
  end

  it 'DB にしかないコードはエントリとして追加されます' do
    DbLoadableItemMaster.create!(:category_name => 'db_loadable',
      :item_no => 1, :item_cd => '09', :name => 'その他')
    enum = build_enum(:when => :everytime)
    expect(enum.options).to eq([['その他', '09'], ['書籍', '01'], ['DVD', '02']])
    expect(enum.key_by_id('09')).to eq(:entry_09)
  end

  it 'コネクションをリークせずに読み込めます' do
    enum = build_enum(:when => :everytime)
    expect { 20.times { enum.names } }.not_to raise_error
  end
end
