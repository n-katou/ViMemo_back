# ベースイメージの指定
FROM ruby:3.1.4

# Dockerfileの冒頭にARGを追加
ARG RAILS_MASTER_KEY

ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

# Node.jsとYarnのインストール
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

# 依存ライブラリのインストール
RUN apt-get update -qq && apt-get install -y postgresql-client

# 作業ディレクトリの設定
WORKDIR /app

# Bundlerのインストール
RUN gem install bundler

# Node.jsとYarnの依存関係ファイルをコピー
COPY package.json yarn.lock ./

# Node.jsの依存関係をインストール
RUN yarn install --frozen-lockfile --network-timeout 600000

# Rubyの依存関係ファイルをコピー
COPY Gemfile Gemfile.lock ./

# Rubyの依存関係をインストール
RUN bundle install

# アプリケーションのファイルをコピー
COPY . .

# アセットをプリコンパイル（RAILS_ENVを設定してプリコンパイルを実行）
RUN RAILS_ENV=production bundle exec rails assets:precompile

# エントリポイントスクリプトをコピーし、実行可能に設定
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# エントリポイントを設定
ENTRYPOINT ["entrypoint.sh"]

# ポートの公開
EXPOSE 3000

# Railsサーバーの起動コマンド
CMD ["rails", "server", "-b", "0.0.0.0"]
