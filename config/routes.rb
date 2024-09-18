Rails.application.routes.draw do

  #backend用
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

  
  # frontend用
  namespace :api do
    namespace :v1 do
  
      # マイページ関連
      get 'mypage', to: 'users#mypage'
      get 'generate_shuffle_playlist', to: 'users#generate_shuffle_playlist'
      post 'update_playlist_order', to: 'users#update_playlist_order'
  
      # ユーザーリソース
      resource :users, only: [:create, :show, :update] do
        collection do
          post :auth_create
          patch :update
          get 'my_notes', to: 'users#my_notes'
        end
      end
  
      # ユーザーログイン・ログアウト
      get 'login', to: 'user_sessions#new'
      post 'login', to: 'user_sessions#create'
      delete 'logout', to: 'user_sessions#destroy'
  
      # いいね動画関連
      get 'favorites', to: 'favorites_videos#index'
      get 'favorites_count', to: 'favorites_videos#favorites_count'
      post 'favorites/save_order', to: 'favorites_videos#save_order'
  
      # YouTube動画リソース
      resources :youtube_videos, only: [:index, :show, :destroy] do
        collection do
          get 'autocomplete'
          get 'fetch_videos_by_genre'
        end
        member do
          get 'likes'
        end
        resources :likes, only: [:create, :destroy]
        resources :notes, only: [:index, :create, :destroy, :update, :edit] do
          collection do
            post 'save_sort_order', to: 'notes#save_sort_order'
          end
          resources :likes, only: [:create, :destroy] do
            collection do
              get 'current_user_like', to: 'likes#current_user_like'
            end
          end
        end
      end
  
      # Google OAuth認証
      post 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_post_api
      get 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_get_api
      get 'oauth/:provider', to: 'google_oauths#oauth', as: :auth_at_provider_api
  
      # パスワードリセットリソース
      resources :password_resets, only: %i[new create edit update]
    end
  end
end
