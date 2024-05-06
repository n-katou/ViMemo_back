class GoogleOauthService
  attr_reader :error_message

  def initialize(code, code_verifier, is_frontend)
    @code = code
    @code_verifier = code_verifier
    @client_id = ENV['GOOGLE_CLIENT_ID']
    @client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @redirect_uri = is_frontend ? ENV['GOOGLE_REDIRECT_URI_FRONTEND'] : ENV['GOOGLE_REDIRECT_URI_BACKEND']
  end


  def authenticate
    begin
      access_token = fetch_access_token
      raise "アクセストークンが取得できませんでした" unless access_token
      user_info = fetch_user_info(access_token)
      raise "ユーザー情報が取得できませんでした" unless user_info
      user = find_or_create_user(user_info)
      raise "ユーザーの作成または検索に失敗しました" unless user
      user
    rescue StandardError => e
      @error_message = e.message
      Rails.logger.error("Google OAuthサービスでエラーが発生しました: #{e.message}, #{e.backtrace.join("\n")}")
      nil
    end
  end

  private

  def fetch_access_token
    uri = URI("https://oauth2.googleapis.com/token")
    response = Net::HTTP.post_form(uri, {
      client_id: @client_id,
      client_secret: @client_secret,
      code: @code,
      code_verifier: @code_verifier,  # PKCEコードベリファイアをリクエストに追加
      redirect_uri: @redirect_uri,
      grant_type: "authorization_code",
    })
    result = JSON.parse(response.body)
    if result["error"]
      raise "アクセストークンの取得に失敗: #{result['error_description'] || result['error']}"
    end
    result["access_token"]
  end

  def fetch_user_info(access_token)
    uri = URI("https://www.googleapis.com/oauth2/v2/userinfo")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    result = JSON.parse(response.body)
    raise "Googleからのユーザー情報の取得に失敗しました" if result["error"]
    result
  end

  def find_or_create_user(user_info)
    user = User.find_or_create_by(email: user_info['email']) do |user|
      user.name = user_info['name']
      user.password = SecureRandom.hex(10)
      user.password_confirmation = user.password
    end
    raise "データベースへのユーザー情報の保存に失敗しました" unless user.persisted?
    user
  end
end
