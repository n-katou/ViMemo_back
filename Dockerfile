# ベースイメージの指定
FROM ruby:3.1.4

# 依存パッケージのインストールとNode.js及びYarnのセットアップ
RUN apt-get update -qq && \
    apt-get install -y nodejs npm && \
    npm install -g yarn && \
    apt-get install -y postgresql-client

# 作業ディレクトリの設定
WORKDIR /app

# 依存関係ファイルのコピー
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# 依存関係のインストール
RUN gem install bundler && \
    bundle install

# アプリケーションのコピー
COPY . /app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# ポートの公開
EXPOSE 3002

# Railsサーバーの起動コマンド
CMD ["rails", "server", "-b", "0.0.0.0"]
