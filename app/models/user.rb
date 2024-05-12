class User < ApplicationRecord
  before_create :generate_auth_token
  authenticates_with_sorcery!
  mount_uploader :avatar, UserImageUploader

  has_many :authentications, dependent: :destroy
  has_many :likes
  has_many :youtube_videos, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :notes, dependent: :destroy

  accepts_nested_attributes_for :authentications

  enum role: { general: 0, admin: 1 }

  validates :password, length: { minimum: 3 }, if: -> { (new_record? || changes[:crypted_password]) && !authentications.present? }
  validates :password, confirmation: true, if: -> { (new_record? || changes[:crypted_password]) && !authentications.present? }
  validates :password_confirmation, presence: true, if: -> { (new_record? || changes[:crypted_password]) && !authentications.present? }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def deliver_reset_password_instructions!
    generate_reset_password_token!
    UserMailer.reset_password_email(self).deliver_now
  end

  def liked_videos
    YoutubeVideo.joins(:likes).where(likes: { user_id: id })
  end

  def generate_auth_token
    self.auth_token = SecureRandom.hex
  end
  
  def self.find_or_create_by_uid(auth_hash)
    find_or_create_by(uid: auth_hash[:uid]) do |user|
      user.email = auth_hash[:info][:email]
      user.name = auth_hash[:info][:name]
      # 必要に応じて他の属性を設定
    end
  end
end
