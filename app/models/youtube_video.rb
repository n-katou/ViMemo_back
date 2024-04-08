class YoutubeVideo < ApplicationRecord
  has_many :notes, dependent: :destroy
  def embed_url
    video_id = self.url.split('=')[1]
    "https://www.youtube.com/embed/#{video_id}"
  end
end
