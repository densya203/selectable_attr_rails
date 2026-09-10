# -*- coding: utf-8 -*-
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe SelectableAttrRails::Helpers do

  class HelperPerson
    include ::SelectableAttr::Base
    selectable_attr :gender do
      entry '1', :male,   '男性'
      entry '2', :female, '女性'
      entry '9', :other,  'その他'
    end
  end

  class HelperRoomSearch
    include ::SelectableAttr::Base
    multi_selectable_attr :room_type do
      entry '01', :single, 'シングル'
      entry '02', :twin,   'ツイン'
      entry '03', :double, 'ダブル'
    end
  end

  let(:person) { HelperPerson.new }
  let(:room_search) { HelperRoomSearch.new }
  let(:view) { build_view(:person => person, :room_search => room_search) }

  describe 'select' do
    it '選択肢を enum から自動生成します' do
      person.gender = '2'
      html = view.select(:person, :gender)
      expect(html).to include('<option value="1">男性</option>')
      expect(html).to include('<option selected="selected" value="2">女性</option>')
      expect(html).to include('<option value="9">その他</option>')
      expect(html).to include('name="person[gender]"')
      expect(html).not_to include('multiple')
    end

    it 'choices を渡した場合は Rails 本来の select として動作します' do
      html = view.select(:person, :gender, [['A', '1'], ['B', '2']])
      expect(html).to include('<option value="1">A</option>')
      expect(html).not_to include('男性')
    end

    it 'multi_selectable_attr では multiple 付きで xxx_ids を出力します' do
      room_search.room_type_ids = ['02']
      html = view.select(:room_search, :room_type)
      expect(html).to include('multiple="multiple"')
      expect(html).to include('name="room_search[room_type_ids][]"')
      expect(html).to include('<option selected="selected" value="02">ツイン</option>')
    end

    it '引数が多すぎる場合は ArgumentError' do
      expect {
        view.select(:person, :gender, [], {}, {}, {})
      }.to raise_error(ArgumentError)
    end

    it '渡した options ハッシュを破壊しません' do
      options = {:include_blank => true}
      view.select(:person, :gender, options)
      expect(options).to eq({:include_blank => true})
    end

    describe 'FormBuilder' do
      it '単一選択' do
        person.gender = '1'
        html = build_form_builder(view, :person, person).select(:gender)
        expect(html).to include('<option selected="selected" value="1">男性</option>')
      end

      it '複数選択 (ビューにインスタンス変数が無くても選択状態が反映される)' do
        room_search.room_type_ids = ['02']
        bare_view = build_view
        html = build_form_builder(bare_view, :room_search, room_search).select(:room_type)
        expect(html).to include('<option value="01">シングル</option>')
        expect(html).to include('<option selected="selected" value="02">ツイン</option>')
      end

      it '単一選択 (ビューにインスタンス変数が無くても選択状態が反映される)' do
        person.gender = '9'
        bare_view = build_view
        html = build_form_builder(bare_view, :person, person).select(:gender)
        expect(html).to include('<option selected="selected" value="9">その他</option>')
      end

      it '複数選択' do
        room_search.room_type_ids = ['01', '03']
        html = build_form_builder(view, :room_search, room_search).select(:room_type)
        expect(html).to include('multiple="multiple"')
        expect(html).to include('<option selected="selected" value="01">シングル</option>')
        expect(html).to include('<option value="02">ツイン</option>')
        expect(html).to include('<option selected="selected" value="03">ダブル</option>')
      end
    end
  end

  describe 'radio_button_group' do
    it 'ブロック無しなら input と label を連結して返します' do
      person.gender = '2'
      html = view.radio_button_group(:person, :gender)
      expect(html).to include('id="person_gender_1"')
      expect(html).to include('<label for="person_gender_1">男性</label>')
      expect(html).to include('checked="checked"')
      expect(html).to be_html_safe
    end

    it 'ブロックを渡すと 1 件ずつ組み立てられます' do
      buf = []
      view.radio_button_group(:person, :gender) do |b|
        b.each do
          buf << [b.entry_hash[:key], b.radio_button, b.label]
        end
      end
      expect(buf.map{|(key, _, _)| key}).to eq([:male, :female, :other])
      expect(buf.first[1]).to include('id="person_gender_1"')
      expect(buf.first[2]).to eq('<label for="person_gender_1">男性</label>')
    end

    it 'label にテキストと属性を指定できます' do
      view.radio_button_group(:person, :gender) do |b|
        b.each do
          expect(b.label('ラベル', :class => 'foo')).to eq(
            '<label for="person_gender_1" class="foo">ラベル</label>')
          break
        end
      end
    end

    it 'entry の名称は HTML エスケープされます' do
      klass = Class.new do
        include ::SelectableAttr::Base
        selectable_attr :kind do
          entry '1', :a, '<script>alert(1)</script>'
        end
      end
      v = build_view(:obj => klass.new)
      html = v.radio_button_group(:obj, :kind)
      expect(html).not_to include('<script>')
      expect(html).to include('&lt;script&gt;')
    end

    it 'FormBuilder 経由でも動作します' do
      html = build_form_builder(view, :person, person).radio_button_group(:gender)
      expect(html).to include('<label for="person_gender_1">男性</label>')
    end
  end

  describe 'check_box_group' do
    it 'ブロック無しなら input と label を連結して返します' do
      room_search.room_type_ids = ['02']
      html = view.check_box_group(:room_search, :room_type)
      expect(html).to include('name="room_search[room_type_ids][]"')
      expect(html).to include('id="room_search_room_type_ids_01"')
      expect(html).to include('<label for="room_search_room_type_ids_01">シングル</label>')
      expect(html).to include('checked="checked"')
      expect(html).to be_html_safe
    end

    it '選択済みの entry にだけ checked が付きます' do
      room_search.room_type_ids = ['02']
      checked = []
      view.check_box_group(:room_search, :room_type) do |b|
        b.each { checked << [b.entry_hash[:key], b.check_box.include?('checked')] }
      end
      expect(checked).to eq([[:single, false], [:twin, true], [:double, false]])
    end

    it ':check_box オプションで input に属性を足せます' do
      html = view.check_box_group(:room_search, :room_type, :check_box => {:class => 'cb'})
      expect(html).to include('class="cb"')
    end

    it '渡した options ハッシュを破壊しません' do
      options = {:check_box => {:class => 'cb'}}
      view.check_box_group(:room_search, :room_type, options)
      expect(options).to eq({:check_box => {:class => 'cb'}})
    end

    it 'entry の名称は HTML エスケープされます' do
      klass = Class.new do
        include ::SelectableAttr::Base
        multi_selectable_attr :tags do
          entry '1', :a, '<img src=x onerror=alert(1)>'
        end
      end
      v = build_view(:obj => klass.new)
      html = v.check_box_group(:obj, :tags)
      expect(html).not_to include('<img')
      expect(html).to include('&lt;img')
    end

    it 'FormBuilder 経由でも動作します' do
      html = build_form_builder(view, :room_search, room_search).check_box_group(:room_type)
      expect(html).to include('<label for="room_search_room_type_ids_01">シングル</label>')
    end
  end

  describe ':base_name オプションを指定したモデル' do
    class BaseNamePerson
      include ::SelectableAttr::Base
      selectable_attr :gender_cd, :base_name => 'sex' do
        entry '1', :male,   '男性'
        entry '2', :female, '女性'
      end
    end

    class BaseNameRoomSearch
      include ::SelectableAttr::Base
      multi_selectable_attr :room_type_cd, :base_name => 'room' do
        entry '01', :single, 'シングル'
        entry '02', :twin,   'ツイン'
      end
    end

    let(:bn_person) { BaseNamePerson.new }
    let(:bn_room) { BaseNameRoomSearch.new }
    let(:bn_view) { build_view(:bn_person => bn_person, :bn_room => bn_room) }

    it 'select が選択肢を組み立てられます' do
      bn_person.gender_cd = '2'
      html = bn_view.select(:bn_person, :gender_cd)
      expect(html).to include('<option value="1">男性</option>')
      expect(html).to include('<option selected="selected" value="2">女性</option>')
    end

    it 'multi の select が xxx_ids を出力します' do
      bn_room.room_ids = ['02']
      html = bn_view.select(:bn_room, :room_type_cd)
      expect(html).to include('multiple="multiple"')
      expect(html).to include('name="bn_room[room_ids][]"')
      expect(html).to include('<option selected="selected" value="02">ツイン</option>')
    end

    it 'radio_button_group が出力できます' do
      html = bn_view.radio_button_group(:bn_person, :gender_cd)
      expect(html).to include('<label for="bn_person_gender_cd_1">男性</label>')
    end

    it 'check_box_group が出力できます' do
      bn_room.room_ids = ['01']
      html = bn_view.check_box_group(:bn_room, :room_type_cd)
      expect(html).to include('name="bn_room[room_ids][]"')
      expect(html).to include('<label for="bn_room_room_ids_01">シングル</label>')
      expect(html).to include('checked="checked"')
    end

    it 'FormBuilder 経由でも動作します' do
      bn_person.gender_cd = '1'
      html = build_form_builder(bn_view, :bn_person, bn_person).select(:gender_cd)
      expect(html).to include('<option selected="selected" value="1">男性</option>')
    end
  end

  describe 'setup の冪等性' do
    it '二重に呼んでも無限再帰しません' do
      SelectableAttrRails.add_features_to_rails
      SelectableAttrRails.add_features_to_rails
      expect(view.select(:person, :gender)).to include('男性')
    end
  end
end
