class Video < ApplicationRecord
  mount_uploader :file_path, VideoUploader
  belongs_to :user
  has_many :notes
end
