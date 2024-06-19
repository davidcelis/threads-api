require "time"

module Threads
  module API
    class Thread
      class List
        attr_reader :threads, :before, :after

        def initialize(json)
          @threads = json["data"].map { |t| Threads::API::Thread.new(t) }

          @before = json.dig("paging", "cursors", "before")
          @after = json.dig("paging", "cursors", "after")
        end
      end

      attr_reader :id, :type, :media_url, :permalink, :user_id, :username, :text, :timestamp, :created_at, :shortcode, :video_thumbnail_url, :children

      def initialize(json)
        @id = json["id"]
        @type = json["media_type"]
        @permalink = json["permalink"]
        @shortcode = json["shortcode"]
        @text = json["text"]
        @media_url = json["media_url"]
        @video_thumbnail_url = json["thumbnail_url"]
        @user_id = json.dig("owner", "id")
        @username = json["username"]
        @is_quote_post = json["is_quote_post"]

        @timestamp = json["timestamp"]
        @created_at = Time.iso8601(@timestamp) if @timestamp

        children = Array(json["children"])
        @children = children.map { |c| Thread.new(c) } if children.any?
      end

      def quote_post?
        @is_quote_post
      end
    end

    class UnpublishedThread
      attr_reader :id

      def initialize(json)
        @id = json["id"]
      end
    end

    class ThreadStatus < UnpublishedThread
      attr_reader :status, :error_message

      def initialize(json)
        super

        @status = json["status"]
        @error_message = json["error_message"]
      end

      def in_progress?
        @status == "IN_PROGRESS"
      end

      def finished?
        @status == "FINISHED"
      end

      def published?
        @status == "PUBLISHED"
      end

      def errored?
        @status == "ERROR"
      end

      def expired?
        @status == "EXPIRED"
      end
    end
  end
end
