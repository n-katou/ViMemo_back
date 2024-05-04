Rails.application.config.session_store :cookie_store, key: '_your_app_session',
  httponly: true, # JavaScriptからのアクセスを防ぐ
  secure: Rails.env.production?, # 本番環境でのみhttps接続時にクッキーを送信
  same_site: :none # クロスオリジンのリクエストでクッキーを送信
