source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.5"

# Railsフレームワーク
gem "rails", "~> 7.0.3", ">= 7.0.3.1"

# アセット管理
gem "sprockets-rails"

# データベース
gem "pg", "~> 1.1"

# サーバー
gem "puma", "~> 5.0"

# JavaScriptバンドリング
gem "jsbundling-rails"

# Turboフレームワーク
gem "turbo-rails"

# Stimulusフレームワーク
gem "stimulus-rails"

# CSSバンドリング
gem "cssbundling-rails"

# JSONビルダー
gem "jbuilder"

# タイムゾーンデータ
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# ブートストラップ高速化
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'rspec-rails', '~> 5.0.0'
  gem 'factory_bot_rails'
end

group :development do
  gem "web-console"
  # gem 'bullet'
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"

end

gem "dockerfile-rails", ">= 1.6", :group => :development

gem 'sorcery', "0.16.3"

# ファイルアップロード
gem 'carrierwave', '~> 2.0'

# 設定管理
gem 'config'

# メール確認用
gem 'letter_opener_web', '~> 2.0'

# 環境変数
gem 'dotenv-rails'

# OAuth認証
gem 'omniauth-google-oauth2'

# HTTPリクエスト
gem 'httparty'

# 検索
gem 'ransack', "3.2.1"

# ページネーション
gem 'kaminari'

# AWS SDK
gem 'aws-sdk-s3', require: false
gem 'fog-aws', '~> 3.0'

# CORS設定
gem 'rack-cors'

# JWTトークン
gem 'jwt'

# 開発およびテスト環境
group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 5.0.0' # RSpecテストフレームワーク
  gem 'factory_bot_rails' # テストデータ生成
end

# 開発環境
group :development do
  gem "web-console" # ウェブコンソール
  gem 'bullet' # N+1クエリ検出
end

# テスト環境
group :test do
  gem "capybara" # 統合テスト
  gem "selenium-webdriver" # ブラウザテスト
end

# Docker
gem "dockerfile-rails", ">= 1.6", group: :development
