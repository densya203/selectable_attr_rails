# -*- coding: utf-8 -*-
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe SelectableAttrRails::Validatable do

  class AnchoredProduct < ActiveRecord::Base
    self.table_name = 'products'
    selectable_attr :product_type_cd do
      entry '01', :book, '書籍'
      entry '02', :dvd,  'DVD'
      validates_format :allow_nil => true
    end
  end

  it '定義されている id は valid' do
    %w[01 02].each do |id|
      expect(AnchoredProduct.new(:product_type_cd => id)).to be_valid
    end
  end

  it 'nil は allow_nil により valid' do
    expect(AnchoredProduct.new(:product_type_cd => nil)).to be_valid
  end

  it '前後に余計な文字が付いた値は invalid (アンカーが効いていること)' do
    ['X01', '01X', 'X01Y', '0102', ' 01'].each do |id|
      product = AnchoredProduct.new(:product_type_cd => id)
      expect(product).not_to be_valid, "#{id.inspect} が valid になっています"
    end
  end

  it '既定のメッセージにエントリ名が並びます' do
    product = AnchoredProduct.new(:product_type_cd => 'XX')
    product.valid?
    expect(product.errors[:product_type_cd]).to eq(
      ['is invalid, must be one of 書籍, DVD'])
  end

  class MessageProduct < ActiveRecord::Base
    self.table_name = 'products'
    selectable_attr :product_type_cd do
      entry '01', :book, '書籍'
      entry '02', :dvd,  'DVD'
      validates_format :allow_nil => true,
        :message => 'は次のいずれかでなければなりません。 #{entries}'
    end
  end

  it ':message を指定できます' do
    product = MessageProduct.new(:product_type_cd => 'XX')
    product.valid?
    expect(product.errors[:product_type_cd]).to eq(
      ['は次のいずれかでなければなりません。 書籍, DVD'])
  end

  class IntegerIdProduct < ActiveRecord::Base
    self.table_name = 'products'
    selectable_attr :price do
      entry 100, :cheap,     '安い'
      entry 200, :expensive, '高い'
      validates_format :allow_nil => true
    end
  end

  it '数値の id でも定義でき、検証できます' do
    expect(IntegerIdProduct.new(:price => 100)).to be_valid
    expect(IntegerIdProduct.new(:price => 300)).not_to be_valid
  end

  class SharedEnumProduct < ActiveRecord::Base
    self.table_name = 'products'
    selectable_attr :product_type_cd, :name do
      entry '01', :book, '書籍'
      entry '02', :dvd,  'DVD'
      validates_format :allow_nil => true,
        :message => 'は次のいずれかでなければなりません。 #{entries}'
    end
  end

  it '同じ enum を複数の属性で使い回してもメッセージが壊れません' do
    product = SharedEnumProduct.new(:product_type_cd => 'XX', :name => 'YY')
    product.valid?
    expect(product.errors[:product_type_cd]).to eq(
      ['は次のいずれかでなければなりません。 書籍, DVD'])
    expect(product.errors[:name]).to eq(
      ['は次のいずれかでなければなりません。 書籍, DVD'])
  end

  it 'validates_format を指定しなければ検証は追加されません' do
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'products'
      selectable_attr :product_type_cd do
        entry '01', :book, '書籍'
      end
    end
    expect(klass.new(:product_type_cd => 'XX')).to be_valid
  end
end
