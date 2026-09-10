source "https://rubygems.org"

# CI から RAILS_VERSION で対象バージョンを切り替えます (例: "~> 7.2.0")
rails_version = ENV['RAILS_VERSION'] || '>= 7.1'

gem "activesupport", rails_version
gem "activerecord",  rails_version
gem "actionpack",    rails_version
gem "actionview",    rails_version
# 本体を並行して開発する場合は SELECTABLE_ATTR_PATH にそのパスを指定します
#   SELECTABLE_ATTR_PATH=../selectable_attr bundle install
if (selectable_attr_path = ENV['SELECTABLE_ATTR_PATH'])
  gem "selectable_attr", :path => selectable_attr_path
else
  gem "selectable_attr", ">= 0.3.22", :github => 'densya203/selectable_attr'
end

group :development, :test do
  gem 'bundler'
  gem 'rake'
  gem "sqlite3", ">= 2.0"
  gem "rspec", "~> 3.13"
  gem "yard"
  gem "simplecov"

  gem 'rdiscount'
end
