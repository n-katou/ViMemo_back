class Video < ApplicationRecord
  mount_uploader :file_path, VideoUploader
  belongs_to :user
  has_many :notes
  has_many :likes, as: :likeable, dependent: :destroy

  validate :image_size_validation

  paginates_per 10
end
