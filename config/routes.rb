Rails.application.routes.draw do
  if Rails.env.development?
    if ENV['ACTUAL_EMAIL_SENDING'] == 'true'
      # 実際のメール送信を行う設定
      # このブロックは空にしておくか、実際のメール送信に関連する設定をここに記述します
    else
      # LetterOpenerWebを使ってメールをプレビューする
      mount LetterOpenerWeb::Engine, at: "/letter_opener"
    end
  end

  # Defines the root path route ("/")
  # root "articles#index"
  root 'tests#index'
  # ユーザー登録機能用のルーティング
  get 'users/mypage', to: 'users#mypage'
  get 'users/edit_mypage', to: 'users#edit', as: 'edit_mypage'
  resources :users, except: [:edit, :show]
  resources :password_resets, only: %i[new create edit update]

  # セッション管理用のルーティング
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete '/logout', to: 'user_sessions#destroy'
  

  post 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_post
  get 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_get
  get 'oauth/:provider', to: 'google_oauths#oauth', as: :auth_at_provider
end
