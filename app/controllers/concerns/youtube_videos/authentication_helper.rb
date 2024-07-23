module YoutubeVideos
  module AuthenticationHelper
    extend ActiveSupport::Concern

    included do
      # ユーザーの認証をオプションにするメソッド
      def optional_authenticate_user!
        authenticate_user! if request.headers['Authorization'].present?
      end

      # ユーザーが動画を取得可能か確認するメソッド
      def user_can_fetch_videos?
        current_user.can_fetch_videos? || current_user.admin?
      end
    end
  end
end
