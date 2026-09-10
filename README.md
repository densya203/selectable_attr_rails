# SelectableAttrRails [![test](https://github.com/densya203/selectable_attr_rails/actions/workflows/test.yml/badge.svg)](https://github.com/densya203/selectable_attr_rails/actions/workflows/test.yml)

## Introduction
selectable_attr_railsは、selectable_attrをRailsで使うときに便利なヘルパーメソッドを提供し、
エントリをDBから取得したり、I18n対応するものです。
https://github.com/densya203/selectable_attr_rails

selectable_attr は、コードが割り振られるような特定の属性について*コード*、*プログラム上での名前*、
*表示するための名前*などをまとめて管理するものです。
https://github.com/densya203/selectable_attr


## 対応バージョン
- Ruby 3.1 以上
- Rails (activesupport / activerecord / actionpack / actionview) 7.1 以上

CI では Ruby 3.1〜3.4 × Rails 7.1〜8.1 の組み合わせでテストしています。


## Install

Gemfile に以下を追加します。

    gem 'selectable_attr', :github => 'densya203/selectable_attr'
    gem 'selectable_attr_rails', :github => 'densya203/selectable_attr_rails'

config/initializers/selectable_attr.rb

    require 'selectable_attr'
    require 'selectable_attr_i18n'
    require 'selectable_attr_rails'
    SelectableAttrRails.setup

`SelectableAttrRails.setup` は何度呼び出しても安全です。


## チュートリアル

### selectヘルパーメソッド
以下のようなモデルが定義してあった場合

    class Person < ActiveRecord::Base
      include ::SelectableAttr::Base

      selectable_attr :gender do
        entry '1', :male, '男性'
        entry '2', :female, '女性'
        entry '9', :other, 'その他'
      end
    end

ビューでは以下のように選択肢を表示することができます。

    <%= form_with(model: @person) do |f| %>
      <%= f.select :gender %>
    <% end %>

form_with、form_for、fields_forを使用しない場合でも、オブジェクト名を設定して使用可能です。

    <%= select :person, :gender %>

また以下のように複数の値を取りうる場合にもこのメソドを使用することが可能です。

    class RoomSearch
      include ::SelectableAttr::Base

      multi_selectable_attr :room_type do
        entry '01', :single, 'シングル'
        entry '02', :twin, 'ツイン'
        entry '03', :double, 'ダブル'
        entry '04', :triple, 'トリプル'
      end
    end

    <%= form_with(model: @room_search) do |f| %>
      <%= f.select :room_type %>
    <% end %>

この場合、出力されるselectタグのmultiple属性が設定され、値は `room_type_ids` として
やりとりされます。

なお、第3引数に選択肢の配列を渡した場合は、Rails本来のselectとして動作します。

    <%= f.select :gender, [['男', '1'], ['女', '2']] %>


### radio_button_groupヘルパーメソッド
 一つだけ値を選択するUIの場合、selectメソッドではなく<input type="radio".../>を出力することも可能です。
 上記Personモデルの場合

    <%= form_with(model: @person) do |f| %>
      <%= f.radio_button_group :gender %>
    <% end %>

 この場合、<input type="radio" .../><label for="xxx">... という風に続けて出力されるので、改行などを出力したい場合は
 引数を一つ取るブロックを渡して以下のように記述します。

    <%= form_with(model: @person) do |f| %>
      <% f.radio_button_group :gender do |b| %>
        <% b.each do %>
          <%= b.radio_button %>
          <%= b.label %>
          <br/>
        <% end %>
      <% end %>
    <% end %>

f.radio_button_groupを呼び出しているERBのタグが、<%= %>から<% %>に変わっていることにご注意ください。


### check_box_groupヘルパーメソッド
 複数の値を選択するUIの場合、selectメソッドではなく<input type="checkbox".../>を出力することも可能です。
 上記RoomSearchクラスの場合

    <%= form_with(model: @room_search) do |f| %>
      <%= f.check_box_group :room_type %>
    <% end %>

 この場合、<input type="checkbox" .../><label for="xxx">... という風に続けて出力されるので、改行などを出力したい場合は
 引数を一つ取るブロックを渡して以下のように記述します。

    <%= form_with(model: @room_search) do |f| %>
      <% f.check_box_group :room_type do |b| %>
        <% b.each do %>
          <%= b.check_box %>
          <%= b.label %>
          <br/>
        <% end %>
      <% end %>
    <% end %>

 f.check_box_groupを呼び出しているERBのタグが、<%= %>から<% %>に変わっていることにご注意ください。

 チェックボックスのタグに属性を追加したい場合は `:check_box` オプションを使います。

    <%= f.check_box_group :room_type, :check_box => {:class => 'room-type'} %>


## DBからのエントリの更新／追加
各エントリの名称を実行時に変更したり、項目を追加することが可能です。

    class RoomPlan < ActiveRecord::Base
      include ::SelectableAttr::Base

      selectable_attr :room_type do
        update_by "select room_type, name from room_types"
        entry '01', :single, 'シングル'
        entry '02', :twin, 'ツイン'
        entry '03', :double, 'ダブル'
        entry '04', :triple, 'トリプル'
      end
    end

というモデルと

     create_table "room_types" do |t|
       t.string   "room_type", :limit => 2
       t.string   "name", :limit => 20
     end

というマイグレーションで作成されるテーブルがあったとします。

### 読み込みのタイミング
`update_by` の `:when` オプションで、SELECT文を実行するタイミングを指定できます。

| :when | 動作 |
|---|---|
| `:first_time` (既定) | 最初にエントリを参照したときだけDBから読み込みます |
| `:everytime` | エントリを参照する度にDBから読み込みます |
| `:never` | DBからは読み込みません |

    selectable_attr :room_type do
      update_by "select room_type, name from room_types", :when => :everytime
      entry '01', :single, 'シングル'
    end

SELECT文の代わりに、エントリのidと名称の配列の配列を返すブロックを渡すこともできます。

    selectable_attr :room_type do
      update_by(:when => :everytime) do
        RoomType.order(:position).pluck(:room_type, :name)
      end
      entry '01', :single, 'シングル'
    end

### エントリの追加
room_typeが"05"、nameが"４ベッド"というレコードがINSERTされた後、
RoomPlan#room_type_optionsなどのselectable_attrが提供するメソッドで
各エントリへアクセスすると、update_byで指定されたSELECT文が実行され、
エントリとしては、

     entry '05', :entry_05, '４ベッド'

が定義されている状態と同じようになります。

このようにコードで定義されていないエントリは、DELETEされると、エントリもなくなります。

### エントリの名称の更新
実行時に名称を変えたい場合には、そのidに該当するレコードを追加／更新します。
例えば、
room_typeが"04"、nameが"３ベッド"というレコードがINSERTされると、その後は
04のエントリはの名称は"３ベッド"に変わり、また別の名称にUPDATEすると、それに
よってエントリの名称も変わります。

このようにコードによってエントリが定義されている場合は、DELETEされてもエントリは削除されず、
DELETE後は、名称が元に戻ります。


## 入力値の検証
`validates_format` を指定すると、定義されているエントリのidだけを受け付ける検証が追加されます。

    class Product < ActiveRecord::Base
      include ::SelectableAttr::Base

      selectable_attr :product_type_cd do
        entry '01', :book, '書籍'
        entry '02', :dvd, 'DVD'
        validates_format :allow_nil => true,
          :message => 'は次のいずれかでなければなりません。 #{entries}'
      end
    end

`:message` の中では `#{entries}` でエントリ名の一覧を参照できます。


## I18n対応
エントリのロケールにおける名称をI18nを内部的に使用して取得できます。

上記RoomPlanモデルの場合、

config/locales/ja.yml

    ja:
      selectable_attrs:
        room_types:
          single: シングル
          twin: ツイン
          double: ダブル
          triple: トリプル

config/locales/en.yml

    en:
      selectable_attrs:
        room_types:
          single: Single
          twin: Twin
          double: Double
          triple: Triple

というYAMLを用意した上で、モデルを以下のように記述します。

    class RoomPlan < ActiveRecord::Base
      include ::SelectableAttr::Base

      selectable_attr :room_type do
        i18n_scope(:selectable_attrs, :room_types)
        entry '01', :single, 'シングル'
        entry '02', :twin, 'ツイン'
        entry '03', :double, 'ダブル'
        entry '04', :triple, 'トリプル'
      end
    end

これで、I18n.localeに設定されているロケールに従って各エントリの名称が変わります。

`SelectableAttr::AkmEnum.i18n_export` で、定義済みの全エントリからロケールファイル用の
ハッシュを書き出すこともできます。


## base_name を指定したモデル

selectable_attr は属性名から `_cd` などを取り除いた **base_name** を使って
メソッドを定義します。`:base_name` オプションや `selectable_attr_name_pattern`、
`attr_enumeable_base` で既定と異なる名前にした場合でも、ヘルパーはそのまま使えます。

    class Person < ActiveRecord::Base
      include ::SelectableAttr::Base

      selectable_attr :gender_cd, :base_name => 'sex' do
        entry '1', :male, '男性'
        entry '2', :female, '女性'
      end
    end

    <%= f.select :gender_cd %>
    <%= f.radio_button_group :gender_cd %>

これには selectable_attr 0.3.22 以上が必要です。


## 開発

    bundle install
    bundle exec rspec

特定のRailsバージョンでテストする場合は `RAILS_VERSION` を指定します。

    RAILS_VERSION='~> 7.2.0' bundle install
    RAILS_VERSION='~> 7.2.0' bundle exec rspec

selectable_attr 本体を並行して修正する場合は `SELECTABLE_ATTR_PATH` に
そのチェックアウト先を指定します。

    SELECTABLE_ATTR_PATH=../selectable_attr bundle install
    SELECTABLE_ATTR_PATH=../selectable_attr bundle exec rspec


## Credit
Copyright (c) 2008 Takeshi AKIMA, released under the MIT license
