module Threads
  module API
    module OAuth2
      class Client
        ShortLivedResponse = Struct.new(:access_token, :user_id, :error_type, :error_message, :code)
        LongLivedResponse = Struct.new(:access_token, :token_type, :expires_in)

        def initialize(client_id:, client_secret:)
          @client_id = client_id
          @client_secret = client_secret
        end

        def access_token(code:, redirect_uri:)
          response = connection.post("/oauth/access_token", {
            client_id: @client_id,
            client_secret: @client_secret,
            code: code,
            grant_type: "authorization_code",
            redirect_uri: redirect_uri
          })

          ShortLivedResponse.new(*response.body.values_at("access_token", "user_id", "error_type", "error_message", "code"))
        end

        def exchange_access_token(access_token)
          response = connection.get("/access_token", {
            client_secret: @client_secret,
            grant_type: "th_exchange_token",
            access_token: access_token
          })

          LongLivedResponse.new(*response.body.values_at("access_token", "token_type", "expires_in"))
        end

        def refresh_access_token(access_token)
          response = connection.get("/refresh_access_token", {
            grant_type: "th_refresh_token",
            access_token: access_token
          })

          LongLivedResponse.new(*response.body.values_at("access_token", "token_type", "expires_in"))
        end

        private

        def connection
          @connection ||= Faraday.new(url: "https://graph.threads.net") do |f|
            f.request :url_encoded

            f.response :json
            f.response :raise_error
          end
        end
      end
    end
  end
end
