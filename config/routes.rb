Rails.application.routes.draw do
  root 'tests#index'
  # ユーザー登録機能用のルーティング
  resources :users, only: [:new, :create]
  # セッション管理用のルーティング
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete '/logout', to: 'user_sessions#destroy'
end
