require 'net/http'
require 'uri'
require 'jwt'

module FirebaseAuth
  ALGORITHM = 'RS256'
  ISSUER_PREFIX = 'https://securetoken.google.com/'
  CERT_URI = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'

  def self.verify_id_token(token)
    unverified_header = decode_token(token, nil, false)
    kid = unverified_header['kid']
    certificate = fetch_certificate(kid)
    public_key = OpenSSL::X509::Certificate.new(certificate).public_key

    decode_token(token, public_key, true)
  end

  def self.decode_token(token, key, verify)
    options = {
      algorithm: ALGORITHM,
      verify_iat: true,
      verify_aud: true,
      verify_iss: true,
      'iss' => "#{ISSUER_PREFIX}#{ENV['FIREBASE_PROJECT_ID']}",
      'aud' => ENV['FIREBASE_PROJECT_ID']
    }

    JWT.decode(token, key, verify, options)
  end

  def self.fetch_certificate(kid)
    uri = URI.parse(CERT_URI)
    response = Net::HTTP.get(uri)
    certificates = JSON.parse(response)
    certificates[kid] or raise 'Certificate not found'
  end
end
