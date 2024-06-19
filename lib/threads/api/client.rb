require_relative "thread"

module Threads
  module API
    class Client
      def initialize(access_token)
        @access_token = access_token
      end

      def list_threads(user_id: "me", **options)
        params = options.slice(:since, :until, :before, :after, :limit).compact
        params[:access_token] = @access_token

        fields = Array(options[:fields]).join(",")
        params[:fields] = fields unless fields.empty?

        response = connection.get("#{user_id}/threads", params)

        Threads::API::Thread::List.new(response.body)
      end

      def get_thread(thread_id, user_id: "me", fields: nil)
        params = {access_token: @access_token}
        params[:fields] = Array(fields).join(",") if fields

        response = connection.get("#{user_id}/threads/#{thread_id}", params)

        Threads::API::Thread.new(response.body)
      end

      private

      def connection
        @connection ||= Faraday.new(url: "https://graph.threads.net/v1.0/") do |f|
          f.request :url_encoded

          f.response :json
          f.response :raise_error
        end
      end
    end
  end
end
