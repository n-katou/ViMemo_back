# ベースイメージの指定
FROM ruby:3.1.5
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# # Node.jsのインストール
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# # # Yarnのインストール
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# 作業ディレクトリの設定
WORKDIR /app

RUN gem install bundler

COPY package.json /app/package.json
COPY yarn.lock /app/yarn.lock
RUN yarn install --frozen-lockfile --network-timeout 600000

# 依存関係ファイルのコピー
# COPY Gemfile Gemfile.lock ./
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# 依存関係のインストール
RUN bundle install

# アプリケーションのコピー
COPY . /app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

RUN yarn build

ENTRYPOINT ["entrypoint.sh"]

# ポートの公開
EXPOSE 3000


# Railsサーバーの起動コマンド
CMD ["rails", "server", "-b", "0.0.0.0"]
