class User < ApplicationRecord
  authenticates_with_sorcery!
  mount_uploader :avatar, UserImageUploader

  has_many :likes
  has_many :youtube_videos, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :notes, dependent: :destroy

  enum role: { general: 0, admin: 1 }

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # パスワードリセットの指示をメールで送信するメソッド
  def deliver_reset_password_instructions!
    generate_reset_password_token!
    url = Rails.application.routes.url_helpers.edit_password_reset_url(reset_password_token, host: ENV['NEXTAUTH_URL'])
    UserMailer.reset_password_email(self, url).deliver_now
  end

  # ユーザーが動画を取得できるかを確認するメソッド
  def can_fetch_videos?
    return true if admin?
    last_video_fetch_date != Date.today || video_fetch_count < 1
  end

  # ユーザーの動画取得記録を更新するメソッド
  def record_video_fetch
    if last_video_fetch_date == Date.today
      increment!(:video_fetch_count)
    else
      update(last_video_fetch_date: Date.today, video_fetch_count: 1)
    end
  end
end
