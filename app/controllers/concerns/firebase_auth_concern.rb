module FirebaseAuthConcern
  extend ActiveSupport::Concern

  ALGORITHM = 'RS256'.freeze
  ISS_URL = 'https://securetoken.google.com/vimemo-63237'.freeze
  CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze

  included do
    def authenticate_token
      authenticate_with_http_token do |token, _options|
        # Rails.logger.debug "Token received: #{token}"
        verified_data = verify_id_token(token)
        # Rails.logger.debug "Verification result: #{verified_data}"
        verified_data
      rescue JWT::DecodeError => e
        # Rails.logger.error "JWT Decode Error: #{e.message}"
        render json: { error: 'Invalid token' }, status: :unauthorized
      rescue StandardError => e
        # Rails.logger.error "Authentication failed: #{e.message}"
        render json: { error: e.message }, status: :unauthorized
        nil
      end
    end

    private

    def fetch_public_keys
      response = HTTParty.get(CERT_URL)
      raise 'Failed to fetch public keys' unless response.success?
      JSON.parse(response.body)
    rescue HTTParty::Error, JSON::ParserError => e
      raise "Public key fetch error: #{e.message}"
    end

    def verify_id_token(token)
      decoded_token = decode_jwt(token, false)
      header = decoded_token[1]
      payload = decoded_token[0]

      unless payload['iss'] == ISS_URL
        error_message = "Expected issuer #{ISS_URL}, but got #{payload['iss']}"
        Rails.logger.error "Authentication failed: #{error_message}"
        raise "発行者が不正です。#{error_message}"
      end

      public_keys = fetch_public_keys
      public_key = public_keys[header['kid']]
      raise '無効な公開鍵です。' unless public_key

      certificate = OpenSSL::X509::Certificate.new(public_key)
      final_decoded_token = decode_jwt(token, true, { algorithm: ALGORITHM, verify_iat: true }, certificate.public_key)

      { uid: final_decoded_token[0]['sub'], decoded_token: final_decoded_token }
    end

    def decode_jwt(token, verify, options = {}, key = nil)
      JWT.decode(token, key, verify, options)
    end
  end
end
