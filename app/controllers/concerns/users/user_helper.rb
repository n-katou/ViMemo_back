module Users
  module UserHelper
    extend ActiveSupport::Concern

    included do
      def generate_jwt_and_render_user(user)
        token = generate_jwt(user.id)
        decoded_token = decode_jwt(token)
        { success: true, token: token, user: user.slice(:id, :email, :name) }
      end

      def generate_response_data(user)
        youtube_video_likes = user.likes.includes(:likeable).where(likeable_type: 'YoutubeVideo').joins('INNER JOIN youtube_videos ON likes.likeable_id = youtube_videos.id').order('youtube_videos.sort_order ASC')
        youtube_video_ids = youtube_video_likes.map { |like| like.likeable.youtube_id }
        youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{youtube_video_ids.join(',')}&loop=1"

        note_likes = user.likes.includes(likeable: { user: {}, youtube_video: {} }).where(likeable_type: 'Note').order(created_at: :desc)

        {
          youtube_video_likes: youtube_video_likes,
          note_likes: note_likes.map { |like| 
            {
              id: like.id,
              likeable_id: like.likeable_id,
              likeable_type: like.likeable_type,
              created_at: like.created_at,
              updated_at: like.updated_at,
              user_id: like.user_id,
              likeable: {
                id: like.likeable.id,
                content: like.likeable.content,
                video_timestamp: like.likeable.video_timestamp,
                is_visible: like.likeable.is_visible,
                likes_count: like.likeable.likes_count,
                youtube_video_id: like.likeable.youtube_video&.id,
                youtube_video_title: like.likeable.youtube_video&.title,
                user: {
                  id: like.likeable.user.id,
                  name: like.likeable.user.name,
                  avatar_url: like.likeable.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
                }
              }
            }
          },
          youtube_playlist_url: youtube_playlist_url,
          avatar_url: user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg",
          role: user.role,
          email: user.email,
          name: user.name 
        }
      end

      def notes_with_videos(user, sort_option)
        sort_column, sort_direction = if sort_option.match(/(.*)_(asc|desc)/)
                                        [$1, $2]
                                      else
                                        ['created_at', 'desc']
                                      end

        sort_column = 'created_at' unless %w[created_at].include?(sort_column)
        sort_direction = 'desc' unless %w[asc desc].include?(sort_direction)

        notes = user.notes.includes(:youtube_video).order("#{sort_column} #{sort_direction}")
        notes_with_videos = notes.map do |note|
          {
            id: note.id,
            content: note.content,
            video_timestamp: note.video_timestamp,
            youtube_video_id: note.youtube_video_id,
            created_at: note.created_at,
            video_title: note.youtube_video.title
          }
        end
        { notes: notes_with_videos }
      end
    end
  end
end
