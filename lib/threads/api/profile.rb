require "time"

module Threads
  module API
    class Profile
      attr_reader :id, :username, :profile_picture_url, :biography

      def initialize(json)
        @id = json["id"]
        @username = json["username"]
        @profile_picture_url = json["profile_picture_url"]
        @biography = json["biography"]
      end

      alias_method :bio, :biography
    end
  end
end
