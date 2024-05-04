Rails.application.config.session_store :cookie_store, key: 'vimemo_session', httponly: true, secure: Rails.env.production?, same_site: :none
