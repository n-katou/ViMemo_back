module JwtHandler
  def generate_jwt(user_id)
    payload = { user_id: user_id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end
end
