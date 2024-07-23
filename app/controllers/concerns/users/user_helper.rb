module Users
  module UserHelper
    extend ActiveSupport::Concern

    included do
      # ユーザーオブジェクトからJWTを生成し、ユーザー情報と共に返すメソッド
      def generate_jwt_and_render_user(user)
        token = generate_jwt(user.id)  # ユーザーIDを基にJWTを生成
        decoded_token = decode_jwt(token)  # トークンをデコード（必要に応じて）
        { success: true, token: token, user: user.slice(:id, :email, :name) }  # JWTとユーザー情報を返す
      end

      # ユーザーのYouTube動画のいいね情報とノート情報を生成し、レスポンスデータとして返すメソッド
      def generate_response_data(user)
        # ユーザーがいいねしたYouTube動画の情報を取得し、ソート順に並べる
        youtube_video_likes = user.likes.includes(:likeable).where(likeable_type: 'YoutubeVideo').joins('INNER JOIN youtube_videos ON likes.likeable_id = youtube_videos.id').order('youtube_videos.sort_order ASC')
        youtube_video_ids = youtube_video_likes.map { |like| like.likeable.youtube_id }  # いいねした動画のIDを抽出
        youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{youtube_video_ids.join(',')}&loop=1"  # プレイリストURLを生成

        # ユーザーがいいねしたノートの情報を取得し、作成日時の降順に並べる
        note_likes = user.likes.where(likeable_type: 'Note').order(created_at: :desc)
        note_ids = note_likes.pluck(:likeable_id)
        notes = Note.where(id: note_ids).includes(:user, :youtube_video).index_by(&:id)

        # レスポンスデータを構築
        {
          youtube_video_likes: youtube_video_likes,
          note_likes: note_likes.map { |like|
            note = notes[like.likeable_id]
            {
              id: like.id,
              likeable_id: like.likeable_id,
              likeable_type: like.likeable_type,
              user_id: like.user_id,
              likeable: note_data(note)
            }
          },
          youtube_playlist_url: youtube_playlist_url,  # プレイリストURLを追加
          avatar_url: user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg",  # ユーザーのアバターURLを追加
          role: user.role,  # ユーザーのロールを追加
          email: user.email,  # ユーザーのメールアドレスを追加
          name: user.name  # ユーザーの名前を追加
        }
      end

      # ユーザーのノートと関連するYouTube動画の情報を取得し、ソートして返すメソッド
      def notes_with_videos(user, sort_option)
        # ソートオプションを解析して、ソートするカラムと方向を決定
        sort_column, sort_direction = if sort_option.match(/(.*)_(asc|desc)/)
                                        [$1, $2]
                                      else
                                        ['created_at', 'desc']
                                      end

        # ソートカラムが指定のカラムでない場合、デフォルトのcreated_atに設定
        sort_column = 'created_at' unless %w[created_at].include?(sort_column)
        # ソート方向が指定の方向でない場合、デフォルトのdescに設定
        sort_direction = 'desc' unless %w[asc desc].include?(sort_direction)

        # ノートと関連するYouTube動画をソートして取得
        notes = user.notes.order("#{sort_column} #{sort_direction}")
        youtube_video_ids = notes.pluck(:youtube_video_id).uniq
        youtube_videos = YoutubeVideo.where(id: youtube_video_ids).index_by(&:id)

        # ノートと関連するYouTube動画の情報をマッピングして返す
        notes_with_videos = notes.map do |note|
          {
            id: note.id,
            content: note.content,
            video_timestamp: note.video_timestamp,
            youtube_video_id: note.youtube_video_id,
            created_at: note.created_at,
            video_title: youtube_videos[note.youtube_video_id]&.title
          }
        end
        { notes: notes_with_videos }
      end

      # ノートデータを構築するヘルパーメソッド
      def note_data(note)
        return nil unless note
        {
          id: note.id,
          content: note.content,
          video_timestamp: note.video_timestamp,
          is_visible: note.is_visible,
          likes_count: note.likes_count,
          youtube_video_id: note.youtube_video_id,
          youtube_video_title: note.youtube_video&.title,
          user: {
            id: note.user.id,
            name: note.user.name,
            avatar_url: note.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
          }
        }
      end
    end
  end
end
