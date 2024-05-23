module Api
  module V1
    class GoogleOauthsController < ApplicationController
      skip_before_action :require_login
      # skip_before_action :verify_authenticity_token

      def oauth
        client_id = ENV['GOOGLE_CLIENT_ID']
        redirect_uri = ENV['GOOGLE_REDIRECT_URI_BACKEND']
        scope = "email profile"
        state = SecureRandom.hex(16)

        oauth_url = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_uri)}&scope=#{CGI.escape(scope)}&state=#{state}&access_type=offline&prompt=consent"

        if request.headers['Frontend-Request'] == 'true'
          render json: { oauthUrl: oauth_url }, status: :ok
        else
          redirect_to oauth_url, allow_other_host: true
        end
      end
    end
  end
end
