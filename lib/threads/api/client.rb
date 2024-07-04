require_relative "profile"
require_relative "thread"

module Threads
  module API
    class Client
      PROFILE_FIELDS = %w[id username threads_profile_picture_url threads_biography]
      POST_FIELDS = %w[
        id
        media_product_type
        media_type
        media_url
        permalink
        owner
        username
        text
        timestamp
        shortcode
        thumbnail_url
        children
        is_quote_post
      ]

      def initialize(access_token)
        @access_token = access_token
      end

      def get_profile(user_id = "me", fields: PROFILE_FIELDS)
        params = {access_token: @access_token}
        params[:fields] = Array(fields).join(",") if fields

        response = connection.get(user_id, params)

        Threads::API::Profile.new(response.body)
      end

      def list_threads(user_id: "me", **options)
        params = options.slice(:since, :until, :before, :after, :limit).compact
        params[:access_token] = @access_token

        fields = if options.key?(:fields)
          Array(options[:fields]).join(",")
        else
          POST_FIELDS.join(",")
        end

        params[:fields] = fields unless fields.empty?

        response = connection.get("#{user_id}/threads", params)

        Threads::API::Thread::List.new(response.body)
      end

      def get_thread(thread_id, fields: POST_FIELDS)
        params = {access_token: @access_token}
        params[:fields] = Array(fields).join(",") if fields

        response = connection.get(thread_id, params)

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

      def create_carousel_thread(children:, text: nil, reply_to_id: nil, reply_control: nil)
        params = {access_token: @access_token, media_type: "CAROUSEL", text: text}
        params[:children] = Array(children).join(",")
        params[:reply_to_id] = reply_to_id if reply_to_id
        params[:reply_control] = reply_control if reply_control

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
