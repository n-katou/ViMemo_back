module Notes
  module NotesHelper
    extend ActiveSupport::Concern

    included do
      before_action :set_video, only: [:create]
      before_action :set_note, only: [:update, :destroy]
      before_action :authorize_user!, only: [:update, :destroy]
  
      # ビデオを設定するメソッド
      def set_video
        @video = YoutubeVideo.find_by(id: params[:youtube_video_id])
        Rails.logger.debug "Video set for note operations: #{@video&.id}"
      end
  
      # ノートを設定するメソッド
      def set_note
        @note = Note.find(params[:id])
        Rails.logger.debug "Note set for operations: #{@note&.id}"
      end
  
      # ユーザーを認証するメソッド
      def authorize_user!
        unless @note.user_id == current_user.id
          Rails.logger.error "Unauthorized access attempt by user ID: #{current_user&.id}"
          render json: { error: 'Not Authorized' }, status: :unauthorized
        end
      end
  
      # ノートのパラメータを許可するメソッド
      def note_params
        params.require(:note).permit(:content, :video_timestamp, :is_visible)
      end
  
      # ノートの動画タイムスタンプをフォーマットするメソッド
      def format_video_timestamp(minutes, seconds)
        format("%02d:%02d", minutes, seconds)
      end
  
      # ソートオプションを取得するメソッド
      def order_option(sort)
        case sort
        when 'created_at_asc'
          { created_at: :asc }
        when 'created_at_desc'
          { created_at: :desc }
        else
          { created_at: :desc }
        end
      end
  
      # ノートのソート順を保存するメソッド
      def save_sorted_order(sorted_note_ids)
        sorted_note_ids.each_with_index do |note_id, index|
          note = Note.find(note_id)
          note.update!(sort_order: index)
        end
      end
    end
  end
end
