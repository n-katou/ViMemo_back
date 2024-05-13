module JwtHandler
  require 'jwt'

  # 秘密鍵を環境変数またはセキュアな設定から取得する
  HMAC_SECRET = ENV['HMAC_SECRET'] || Rails.application.secrets.secret_key_base

  # トークンの有効期限を設定ファイルから取得する、デフォルトは4時間
  TOKEN_LIFETIME = Rails.application.config.try(:jwt_lifetime) || 4 * 3600

  def generate_jwt(user_id)
    expiration = Time.now.to_i + TOKEN_LIFETIME
    payload = { user_id: user_id, exp: expiration }
    JWT.encode(payload, HMAC_SECRET, 'HS256')
  rescue JWT::EncodeError => e
    Rails.logger.error "JWT Encode Error: #{e.message}"
    nil
  end

  def decode_jwt(token)
    JWT.decode(token, HMAC_SECRET, true, { algorithm: 'HS256' }).first
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT Decode Error: #{e.message}"
    nil
  end
end
