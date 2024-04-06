class User < ApplicationRecord
  authenticates_with_sorcery!
  mount_uploader :avatar, UserImageUploader
  has_one_attached :avatar

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :email, presence: true, uniqueness: true

  validates :reset_password_token, uniqueness: true, allow_nil: true

  def deliver_reset_password_instructions!
    generate_reset_password_token!
    UserMailer.reset_password_email(self).deliver_now
  end
end
