class YoutubeVideo < ApplicationRecord
  has_many :notes, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  belongs_to :user

  paginates_per 10
  
  def embed_url
    video_id = self.url.split('=')[1]
    "https://www.youtube.com/embed/#{video_id}"
  end
  
  def liked_by?(user)
    likes.where(user: user).exists?
  end
end
