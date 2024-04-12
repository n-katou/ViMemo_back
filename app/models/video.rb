class Video < ApplicationRecord
  mount_uploader :file_path, VideoUploader
  belongs_to :user
  has_many :notes
  has_many :likes, as: :likeable, dependent: :destroy

  validate :image_size_validation

  private

  def image_size_validation
    errors[:image] << "should be less than 5MB" if image.size > 5.megabytes
  end
end
