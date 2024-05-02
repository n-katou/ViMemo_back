require 'net/http'
require 'uri'
require 'json'

class GoogleOauthService
  def initialize(code)
    @code = code
    @client_id = ENV['GOOGLE_CLIENT_ID']
    @client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @redirect_uri = "https://vimemo.fly.dev/oauth/callback?provider=google"
  end

  def authenticate
    access_token = fetch_access_token
    user_info = fetch_user_info(access_token)
    find_or_create_user(user_info) if user_info
  end

  private

  def fetch_access_token
    uri = URI("https://oauth2.googleapis.com/token")
    response = Net::HTTP.post_form(uri, {
      code: @code,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: @redirect_uri,
      grant_type: "authorization_code"
    })
    JSON.parse(response.body)["access_token"]
  end

  def fetch_user_info(access_token)
    uri = URI("https://www.googleapis.com/oauth2/v2/userinfo")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def find_or_create_user(user_info)
    User.find_or_create_by(email: user_info['email']) do |user|
      user.name = user_info['name']
      user.password = SecureRandom.hex(10)
      user.password_confirmation = user.password
    end
  end
end
