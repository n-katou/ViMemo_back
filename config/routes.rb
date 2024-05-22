Rails.application.routes.draw do
  root 'tops#index'
  get 'tops/agreement', to: 'tops#agreement', as: 'agreement'
  get 'tops/privacy', to: 'tops#privacy', as: 'privacy'

  # ユーザー登録機能用のルーティング
  get 'users/mypage', to: 'users#mypage'
  get 'users/edit_mypage', to: 'users#edit', as: 'edit_mypage'
  resources :users, except: [:edit, :show, :index]
  resources :password_resets, only: %i[new create edit update]

  # セッション管理用のルーティング
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'

  post 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_post
  get 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_get
  get 'oauth/:provider', to: 'google_oauths#oauth', as: :auth_at_provider

  resources :youtube_videos, only: [:index, :show, :destroy] do
    get 'fetch_videos_by_genre', on: :collection
    resources :likes, only: [:create, :destroy]
    resources :notes, only: [:create, :destroy, :update, :edit]
  end

  get 'notes/index', to: 'notes#index', as: :notes

  get 'favorites', to: 'combined_videos#favorites', as: 'favorites_videos'
  resources :combined_videos, only: %i[index]

  namespace :admin do
    root "users#index"
    resources :users, only: %i[index edit update show destroy]
    resources :videos, only: %i[index show]
  end

  namespace :api do
    namespace :v1 do
      get 'favorites', to: 'combined_videos#favorites', as: 'favorites_videos'
      get 'mypage', to: 'users#mypage'
      resource :users, only: [:create, :show, :update] do
        collection do
          post :auth_create
          patch :update
        end
      end
      get 'login', to: 'user_sessions#new'
      post 'login', to: 'user_sessions#create'
      delete 'logout', to: 'user_sessions#destroy'
      resources :youtube_videos, only: [:index, :show, :destroy] do
        member do
          get 'likes'
        end
        resources :likes, only: [:create, :destroy]
        get 'fetch_videos_by_genre', on: :collection
        resources :notes, only: [:index, :create, :destroy, :update, :edit] do
          resources :likes, only: [:create, :destroy] do
            collection do
              get 'current_user_like', to: 'likes#current_user_like'
            end
          end
        end
      end
      resources :notes, only: [:index, :create, :update, :destroy]  # この行を追加
      post 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_post_api
      get 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_get_api
      get 'oauth/:provider', to: 'google_oauths#oauth', as: :auth_at_provider_api

      # シャッフルプレイリストURLを生成するエンドポイントを追加
      get 'generate_shuffle_playlist', to: 'users#generate_shuffle_playlist'
    end
  end
end
