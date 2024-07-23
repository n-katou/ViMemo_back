class YoutubeVideo < ApplicationRecord
  has_many :notes, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  belongs_to :user

  paginates_per 10
end
