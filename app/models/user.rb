class User < ApplicationRecord
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
    url = Rails.application.routes.url_helpers.edit_password_reset_url(reset_password_token, host: ENV['NEXTAUTH_URL'])
    UserMailer.reset_password_email(self, url).deliver_now
  end

  def liked_videos
    YoutubeVideo.joins(:likes).where(likes: { user_id: id })
  end
  
  def can_fetch_videos?
    Rails.logger.info("Checking if user can fetch videos. Role: #{self.role}, Last fetch date: #{self.last_video_fetch_date}, Fetch count: #{self.video_fetch_count}")
    return true if admin?
    last_video_fetch_date != Date.today || video_fetch_count < 1
  end

  def record_video_fetch
    Rails.logger.info("Recording video fetch for user #{self.id}. Current fetch count: #{self.video_fetch_count}, Last fetch date: #{self.last_video_fetch_date}")
    if last_video_fetch_date == Date.today
      increment!(:video_fetch_count)
    else
      update(last_video_fetch_date: Date.today, video_fetch_count: 1)
    end
    Rails.logger.info("Updated video fetch count for user #{self.id}. New fetch count: #{self.video_fetch_count}, New last fetch date: #{self.last_video_fetch_date}")
  end
end
