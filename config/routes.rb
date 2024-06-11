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
      # current_userのいいね動画を取得
      get 'favorites', to: 'combined_videos#favorites', as: 'favorites_videos'
      # current_userのいいね動画のカウントを取得
      get 'favorites_count', to: 'combined_videos#index', as: 'favorites_videos_count'
      # いいね動画の並び替え順序を保存
      post 'favorites/save_order', to: 'combined_videos#save_order'
      
      # マイページ情報を取得
      get 'mypage', to: 'users#mypage'
  
      # ユーザーリソース
      resource :users, only: [:create, :show, :update] do
        collection do
          # 認証付きユーザー作成
          post :auth_create
          # ユーザー情報の更新
          patch :update
          # 動画と一緒にユーザーノートを取得
          get 'notes_with_videos', to: 'users#notes_with_videos'
        end
      end
  
      # ユーザーログイン
      get 'login', to: 'user_sessions#new'
      post 'login', to: 'user_sessions#create'
      # ユーザーログアウト
      delete 'logout', to: 'user_sessions#destroy'
  
      # YouTube動画リソース
      resources :youtube_videos, only: [:index, :show, :destroy] do
        collection do
          # オートコンプリート機能
          get 'autocomplete'
          # ジャンルごとに動画を取得
          get 'fetch_videos_by_genre'
        end
        member do
          # 動画のいいね一覧を取得
          get 'likes'
        end
        # いいねリソース
        resources :likes, only: [:create, :destroy]
        # ノートリソース
        resources :notes, only: [:index, :create, :destroy, :update, :edit] do
          collection do
            post 'save_sort_order', to: 'notes#save_sort_order'
          end
          # ノートのいいねリソース
          resources :likes, only: [:create, :destroy] do
            collection do
              # 現在のユーザーのいいねを取得
              get 'current_user_like', to: 'likes#current_user_like'
            end
          end
        end
      end
  
      # ノートリソース（個別）
      resources :notes, only: [:destroy]

      # Google OAuth認証
      post 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_post_api
      get 'oauth/callback', to: 'google_oauths#callback', as: :oauth_callback_get_api
      get 'oauth/:provider', to: 'google_oauths#oauth', as: :auth_at_provider_api
  
      # シャッフルプレイリストURLを生成するエンドポイント
      get 'generate_shuffle_playlist', to: 'users#generate_shuffle_playlist'
  
      # パスワードリセットリソース
      resources :password_resets, only: %i[new create edit update]
    end
  end
end
