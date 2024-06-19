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

      def create_thread(type: "TEXT", text: nil, image_url: nil, video_url: nil, reply_to_id: nil, reply_control: nil)
        params = {access_token: @access_token, media_type: type, text: text}
        params[:reply_to_id] = reply_to_id if reply_to_id
        params[:reply_control] = reply_control if reply_control

        case type
        when "IMAGE"
          params[:image_url] = image_url || raise(ArgumentError, "The `:image_url` option is required when the post's type is \"IMAGE\"")
        when "VIDEO"
          params[:video_url] = video_url || raise(ArgumentError, "The `:video_url` option is required when the post's type is \"VIDEO\"")
        when "TEXT"
          raise ArgumentError, "The `:text` option is required when the post's type is \"TEXT\"" if text.nil? || text.empty?
        else
          raise ArgumentError, "Invalid post type: #{type}. Must be one of: \"TEXT\", \"IMAGE\", or \"VIDEO\""
        end

        response = connection.post("me/threads", params)

        Threads::API::UnpublishedThread.new(response.body)
      end

      def get_thread_status(thread_id)
        response = connection.get(thread_id, {
          access_token: @access_token,
          fields: "id,status,error_message"
        })

        Threads::API::ThreadStatus.new(response.body)
      end

      def create_carousel_item(type:, image_url: nil, video_url: nil)
        params = {access_token: @access_token, media_type: type, is_carousel_item: true}

        case type
        when "IMAGE"
          params[:image_url] = image_url || raise(ArgumentError, "The `:image_url` option is required when the item's type is \"IMAGE\"")
        when "VIDEO"
          params[:video_url] = video_url || raise(ArgumentError, "The `:video_url` option is required when the item's type is \"VIDEO\"")
        else
          raise ArgumentError, "Invalid item type: #{type}. Must be \"IMAGE\" or \"VIDEO\""
        end

        response = connection.post("me/threads", params)

        Threads::API::UnpublishedThread.new(response.body)
      end

      def create_carousel_thread(children:, text: nil)
        params = {access_token: @access_token, media_type: "CAROUSEL", text: text}
        params[:children] = Array(children).join(",")

        raise ArgumentError, "At least one item must be present in the `:children` option" if params[:children].empty?

        response = connection.post("me/threads", params)

        Threads::API::UnpublishedThread.new(response.body)
      end

      def publish_thread(id)
        response = connection.post("me/threads_publish", {access_token: @access_token, creation_id: id})

        Threads::API::ThreadStatus.new(response.body)
      end
      alias_method :publish_carousel, :publish_thread

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
