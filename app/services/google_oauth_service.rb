class GoogleOauthService
  def initialize(code)
    @code = code
    @client_id = ENV['GOOGLE_CLIENT_ID']
    @client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @redirect_uri = "https://vimemo.fly.dev/oauth/callback?provider=google"
    # @redirect_uri = "http://localhost:3000/oauth/callback?provider=google"
  end

  def authenticate
    access_token = fetch_access_token(@code)
    user_info = fetch_user_info(access_token)
    find_or_create_user(user_info)
  end

  private

  def fetch_access_token(code)
    uri = URI.parse("https://oauth2.googleapis.com/token")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/x-www-form-urlencoded"
    request.set_form_data(code: code, client_id: @client_id, client_secret: @client_secret, redirect_uri: @redirect_uri, grant_type: "authorization_code")
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
    JSON.parse(response.body)["access_token"]
  end

  def fetch_user_info(access_token)
    uri = URI.parse("https://www.googleapis.com/oauth2/v2/userinfo")
    uri.query = URI.encode_www_form(access_token: access_token)
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  end

  def find_or_create_user(user_info)
    User.find_or_create_by(email: user_info['email']) do |user|
      user.name = user_info['name']
      user.password = SecureRandom.hex(10)  # 例としてランダムパスワードを設定
      user.password_confirmation = user.password
    end
  end
end
