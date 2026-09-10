# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'selectable_attr_rails/version'

Gem::Specification.new do |s|
  s.name        = "selectable_attr_rails"
  s.version     = SelectableAttrRails::VERSION
  s.authors     = ["Takeshi Akima"]
  s.email       = "akm2000@gmail.com"
  s.summary     = "selectable_attr_rails makes possible to use selectable_attr in rails application"
  s.description = "selectable_attr を Rails で使うためのヘルパーメソッド、" <<
                  "DB からのエントリ読み込み、I18n 連携を提供します。"
  s.homepage    = "https://github.com/densya203/selectable_attr_rails"
  s.licenses    = ["MIT"]

  s.required_ruby_version = ">= 3.1"
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]
  # cwd に依存しないように gem のルートを基準にします
  s.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb"] +
      %w[MIT-LICENSE README.md Rakefile init.rb selectable_attr_rails.gemspec]
  end

  s.add_runtime_dependency "activesupport", ">= 6.1"
  s.add_runtime_dependency "activerecord",  ">= 6.1"
  s.add_runtime_dependency "actionpack",    ">= 6.1"
  s.add_runtime_dependency "actionview",    ">= 6.1"
  s.add_runtime_dependency "selectable_attr", ">= 0.3.22"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "sqlite3", ">= 2.0"
  s.add_development_dependency "yard"
  s.add_development_dependency "simplecov"
end
