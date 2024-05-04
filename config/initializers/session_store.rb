Rails.application.config.session_store :cookie_store, key: '_your_app_session',
  expire_after: 2.weeks, # 2週間でセッションが無効に
  httponly: true,
  secure: Rails.env.production?,
  same_site: :none
