source "https://rubygems.org"

# CI から RAILS_VERSION で対象バージョンを切り替えます (例: "~> 7.2.0")
rails_version = ENV['RAILS_VERSION'] || '>= 6.1'
# Rails 6.1 系を明示的に指定した場合だけ、その世代に必要な gem を固定します
rails_61 = rails_version.start_with?('~> 6.1')

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

if rails_61
  # Rails 6.1 は sqlite3 1.x までしか対応していません
  gem "sqlite3", "~> 1.4"
  # Ruby 3.3 以降で bundled gem になった標準ライブラリと、
  # Rails 6.1 が動かない concurrent-ruby 1.3.5 の回避
  gem "concurrent-ruby", "1.3.4"
  gem "base64"
  gem "bigdecimal"
  gem "drb"
  gem "logger"
  gem "mutex_m"
  gem "ostruct"
end

group :development, :test do
  gem 'bundler'
  gem 'rake'
  gem "sqlite3", ">= 2.0" unless rails_61
  gem "rspec", "~> 3.13"
  gem "yard"
  gem "simplecov"

  gem 'rdiscount'
end
