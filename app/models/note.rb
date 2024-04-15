class Note < ApplicationRecord
  belongs_to :user
  belongs_to :youtube_video, optional: true, counter_cache: true
  belongs_to :video, optional: true
  has_many :likes, as: :likeable, dependent: :destroy
  validates :content, presence: true
  validates :video_timestamp, presence: true, format: { with: /\A\d{1,2}:\d{2}\z/, message: "は「分:秒」形式で入力してください。例: 1:23" }
end
