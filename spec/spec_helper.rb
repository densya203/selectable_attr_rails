# -*- coding: utf-8 -*-
require 'rubygems'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_view'

require 'selectable_attr'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'init')

require 'yaml'
config = YAML.safe_load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')),
  :permitted_classes => [Symbol], :aliases => true)
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

load(File.join(File.dirname(__FILE__), 'schema.rb'))

# ActionView のヘルパーを単体で叩くためのビューコンテキストを作ります。
def build_view(assigns = {})
  lookup_context = ActionView::LookupContext.new([])
  view = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
  assigns.each{|name, value| view.instance_variable_set("@#{name}", value)}
  view
end

def build_form_builder(view, object_name, object, options = {})
  ActionView::Helpers::FormBuilder.new(object_name, object, view, options)
end
