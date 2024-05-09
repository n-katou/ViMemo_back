module FirebaseAuthConcern
  extend ActiveSupport::Concern

  ALGORITHM = 'RS256'.freeze
  ISS_URL = 'https://securetoken.google.com/vimemo-63237'.freeze
  CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze

  included do
    def authenticate_token
      authenticate_with_http_token do |token, _options|
        Rails.logger.debug "Token received: #{token}"
        verified_data = verify_id_token(token)
        Rails.logger.debug "Verification result: #{verified_data}"
        verified_data
      rescue StandardError => e
        Rails.logger.error "Authentication failed: #{e.message}"
        render json: { error: e.message }, status: :unauthorized
        nil
      end
    end

    private

    def verify_id_token(token)
      decoded_token = decode_jwt(token, false)
      header = decoded_token[0]  # JWTの最初の部分がヘッダー
      payload = decoded_token[1] # 2番目の部分がペイロード
    
      Rails.logger.debug "Decoded header: #{header.inspect}"
      Rails.logger.debug "Decoded payload: #{payload.inspect}"
      
      raise 'トークンが正しくありません。' if header.nil? || payload.nil?
      
      Rails.logger.debug "Issuer from token: #{payload['iss'].inspect}"
      raise "発行者が不正です。期待される発行者: #{ISS_URL}, 受け取った発行者: #{payload['iss'].inspect}" unless payload['iss'] == ISS_URL
      
      public_key = fetch_public_keys[header['kid']]
      raise '無効な公開鍵です。' unless public_key
      
      certificate = OpenSSL::X509::Certificate.new(public_key)
      decoded_token = decode_jwt(token, true, { algorithm: ALGORITHM, verify_iat: true }, certificate.public_key)
      
      { uid: decoded_token[0]['sub'], decoded_token: decoded_token }
    end

    def decode_jwt(token, verify, options = {}, key = nil)
      JWT.decode(token, key, verify, options)
    end

    def fetch_public_keys
      response = HTTParty.get(CERT_URL)
      raise 'Failed to fetch public keys' unless response.success?
      JSON.parse(response.body)
    end

    def valid_token?(header, payload)
      unless payload['iss'] == ISS_URL
        raise "発行者が不正です。期待される発行者: #{ISS_URL}, 受け取った発行者: #{payload['iss']}"
      end
      unless payload['aud'] == 'vimemo-63237'
        raise "トークンの対象者が不正です。期待される対象者: vimemo-63237, 受け取った対象者: #{payload['aud']}"
      end
      true
    end
  end
end
