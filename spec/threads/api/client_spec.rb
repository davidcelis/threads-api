# frozen_string_literal: true

require "spec_helper"

RSpec.describe Threads::API::Client do
  let(:client) { described_class.new("ACCESS_TOKEN") }

  describe "#get_profile" do
    let(:response_body) do
      {id: "1234567890"}.to_json
    end

    let(:params) { {} }
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/v1.0/me")
        .with(query: params.merge(access_token: "ACCESS_TOKEN"))
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:profile) { client.get_profile(**params) }

    it "returns a response object with the user's profile" do
      expect(profile.id).to eq("1234567890")
    end

    context "when requesting all fields" do
      let(:response_body) do
        {
          id: "1234567890",
          username: "davidcelis",
          profile_picture_url: "https://scontent-sjc3-1.cdninstagram.com/link/to/profile/picture/on/threads/",
          biography: "Cowboy coder."
        }.to_json
      end

      let(:params) do
        {
          fields: ["id", "username", "profile_picture_url", "biography"]
        }
      end
      let!(:request) do
        stub_request(:get, "https://graph.threads.net/v1.0/1234567890")
          .with(query: {access_token: "ACCESS_TOKEN", fields: "id,username,profile_picture_url,biography"})
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      let(:profile) { client.get_profile("1234567890", **params) }

      it "fully hydrates the Profile" do
        expect(profile.id).to eq("1234567890")
        expect(profile.username).to eq("davidcelis")
        expect(profile.profile_picture_url).to eq("https://scontent-sjc3-1.cdninstagram.com/link/to/profile/picture/on/threads/")
        expect(profile.biography).to eq("Cowboy coder.")
      end
    end
  end

  describe "#list_threads" do
    let(:before_cursor) { "QVFIUkFyUFVVczIwWjVNaDVieUxHbW9vWFVqNkh0MHU0cFZARVHRTR3ZADSUxnaTdTdXl2eXBqUG4yX0RLVTF3TUszWW1nXzVJcmU5bnd2QmV2ZAVVDNVFXcFRB" }
    let(:after_cursor) { "QVFIUkZA4QzVhQW1XdTFibU9lRUF2YUR1bEVRQkhVZAWRCX2d3TThUMGVoQ3ZAwT1E4bElEa0JzNGJqV2ZAtUE00U0dMTnhZAdXpBUWN3OUdVSF9aSGZAhYXlGSDFR" }
    let(:response_body) do
      {
        data: [{
          id: "11111111111111111",
          media_product_type: "THREADS",
          media_type: "CAROUSEL_ALBUM",
          text: "Hello, world!",
          permalink: "https://www.threads.net/@davidcelis/post/c8yKXdQp0qR",
          owner: {id: "1234567890"},
          username: "davidcelis",
          timestamp: "2024-06-18T01:23:45Z",
          shortcode: "c8yKXdQp0qR",
          is_quote_post: false,
          children: [
            {
              id: "22222222222222222",
              media_type: "IMAGE",
              media_url: "https://www.threads.net/image.jpg",
              owner: {id: "1234567890"},
              username: "davidcelis",
              timestamp: "2024-06-18T01:23:45Z"
            },
            {
              id: "33333333333333333",
              media_type: "VIDEO",
              media_url: "https://www.threads.net/video.mp4",
              thumbnail_url: "https://www.threads.net/video.jpg",
              owner: {id: "1234567890"},
              username: "davidcelis",
              timestamp: "2024-06-18T01:23:45Z"
            }
          ]
        }],
        paging: {cursors: {before: before_cursor, after: after_cursor}}
      }.to_json
    end

    let(:params) { {} }
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/v1.0/me/threads")
        .with(query: params.merge(access_token: "ACCESS_TOKEN", fields: Threads::API::Client::POST_FIELDS.join(",")))
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    it "returns a list of fully hydrated Threads by default" do
      expect(response.threads.size).to eq(1)

      thread = response.threads.first
      expect(thread.id).to eq("11111111111111111")
      expect(thread.type).to eq("CAROUSEL_ALBUM")
      expect(thread.text).to eq("Hello, world!")
      expect(thread.permalink).to eq("https://www.threads.net/@davidcelis/post/c8yKXdQp0qR")
      expect(thread.user_id).to eq("1234567890")
      expect(thread.username).to eq("davidcelis")
      expect(thread.timestamp).to eq("2024-06-18T01:23:45Z")
      expect(thread.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))
      expect(thread.shortcode).to eq("c8yKXdQp0qR")
      expect(thread).not_to be_quote_post

      expect(thread.children.size).to eq(2)

      child_1 = thread.children.find { |c| c.id == "22222222222222222" }
      expect(child_1.type).to eq("IMAGE")
      expect(child_1.media_url).to eq("https://www.threads.net/image.jpg")
      expect(child_1.video_thumbnail_url).to be_nil
      expect(child_1.user_id).to eq("1234567890")
      expect(child_1.username).to eq("davidcelis")
      expect(child_1.timestamp).to eq("2024-06-18T01:23:45Z")
      expect(child_1.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))

      child_2 = thread.children.find { |c| c.id == "33333333333333333" }
      expect(child_2.type).to eq("VIDEO")
      expect(child_2.media_url).to eq("https://www.threads.net/video.mp4")
      expect(child_2.video_thumbnail_url).to eq("https://www.threads.net/video.jpg")
      expect(child_2.user_id).to eq("1234567890")
      expect(child_2.username).to eq("davidcelis")
      expect(child_2.timestamp).to eq("2024-06-18T01:23:45Z")
      expect(child_2.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))
    end

    let(:response) { client.list_threads(**params) }

    context "when passing additional options" do
      let(:params) do
        {
          since: "2024-06-18",
          until: "2024-06-19",
          before: "before_cursor",
          after: "after_cursor",
          limit: 100,
          fields: "id,text,timestamp"
        }
      end

      let(:response_body) do
        {
          data: [
            {id: "11111111111111111", text: "Hello, world!", timestamp: "2024-06-18T01:23:45Z"},
            {id: "22222222222222222", text: "It's me!", timestamp: "2024-06-18T12:34:56Z"},
            {id: "33333333333333333", text: "Ok, see ya later!", timestamp: "2024-06-18T23:45:01Z"}
          ],
          paging: {cursors: {before: before_cursor, after: after_cursor}}
        }.to_json
      end

      let!(:request) do
        stub_request(:get, "https://graph.threads.net/v1.0/12345/threads")
          .with(query: params.merge(access_token: "ACCESS_TOKEN"))
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      let(:response) { client.list_threads(user_id: 12345, **params) }

      it "returns a response object with threads and cursors for pagination" do
        post_1 = response.threads.find { |t| t.id == "11111111111111111" }
        expect(post_1.text).to eq("Hello, world!")
        expect(post_1.timestamp).to eq("2024-06-18T01:23:45Z")
        expect(post_1.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))

        post_2 = response.threads.find { |t| t.id == "22222222222222222" }
        expect(post_2.text).to eq("It's me!")
        expect(post_2.timestamp).to eq("2024-06-18T12:34:56Z")
        expect(post_2.created_at).to eq(Time.utc(2024, 6, 18, 12, 34, 56))

        post_3 = response.threads.find { |t| t.id == "33333333333333333" }
        expect(post_3.text).to eq("Ok, see ya later!")
        expect(post_3.timestamp).to eq("2024-06-18T23:45:01Z")
        expect(post_3.created_at).to eq(Time.utc(2024, 6, 18, 23, 45, 1))
      end

      it "supports passing fields as an array" do
        params[:fields] = %w[id text timestamp]

        expect(response.threads).to all(have_attributes(id: a_string_matching(/\d{17}/), text: instance_of(String), created_at: an_instance_of(Time)))

        expect(request).to have_been_made
      end
    end

    context "when requesting all fields" do
      let(:params) do
        {
          fields: "id,media_product_type,media_type,media_url,permalink,owner,username,text,timestamp,shortcode,thumbnail_url,children,is_quote_post"
        }
      end
    end
  end

  describe "#get_thread" do
    let(:response_body) do
      {
        id: "11111111111111111",
        media_product_type: "THREADS",
        media_type: "CAROUSEL_ALBUM",
        text: "Hello, world!",
        permalink: "https://www.threads.net/@davidcelis/post/c8yKXdQp0qR",
        owner: {id: "1234567890"},
        username: "davidcelis",
        timestamp: "2024-06-18T01:23:45Z",
        shortcode: "c8yKXdQp0qR",
        is_quote_post: false,
        children: [
          {
            id: "22222222222222222",
            media_type: "IMAGE",
            media_url: "https://www.threads.net/image.jpg",
            owner: {id: "1234567890"},
            username: "davidcelis",
            timestamp: "2024-06-18T01:23:45Z"
          },
          {
            id: "33333333333333333",
            media_type: "VIDEO",
            media_url: "https://www.threads.net/video.mp4",
            thumbnail_url: "https://www.threads.net/video.jpg",
            owner: {id: "1234567890"},
            username: "davidcelis",
            timestamp: "2024-06-18T01:23:45Z"
          }
        ]
      }.to_json
    end

    let(:params) { {} }
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/v1.0/11111111111111111")
        .with(query: params.merge(access_token: "ACCESS_TOKEN", fields: Threads::API::Client::POST_FIELDS.join(",")))
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:thread) { client.get_thread("11111111111111111") }

    it "returns a fully hydrated Thread by default" do
      expect(thread.id).to eq("11111111111111111")
      expect(thread.type).to eq("CAROUSEL_ALBUM")
      expect(thread.text).to eq("Hello, world!")
      expect(thread.permalink).to eq("https://www.threads.net/@davidcelis/post/c8yKXdQp0qR")
      expect(thread.user_id).to eq("1234567890")
      expect(thread.username).to eq("davidcelis")
      expect(thread.timestamp).to eq("2024-06-18T01:23:45Z")
      expect(thread.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))
      expect(thread.shortcode).to eq("c8yKXdQp0qR")
      expect(thread).not_to be_quote_post

      expect(thread.children.size).to eq(2)

      child_1 = thread.children.find { |c| c.id == "22222222222222222" }
      expect(child_1.type).to eq("IMAGE")
      expect(child_1.media_url).to eq("https://www.threads.net/image.jpg")
      expect(child_1.video_thumbnail_url).to be_nil
      expect(child_1.user_id).to eq("1234567890")
      expect(child_1.username).to eq("davidcelis")
      expect(child_1.timestamp).to eq("2024-06-18T01:23:45Z")
      expect(child_1.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))

      child_2 = thread.children.find { |c| c.id == "33333333333333333" }
      expect(child_2.type).to eq("VIDEO")
      expect(child_2.media_url).to eq("https://www.threads.net/video.mp4")
      expect(child_2.video_thumbnail_url).to eq("https://www.threads.net/video.jpg")
      expect(child_2.user_id).to eq("1234567890")
      expect(child_2.username).to eq("davidcelis")
      expect(child_2.timestamp).to eq("2024-06-18T01:23:45Z")
      expect(child_2.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))
    end

    context "when requesting specific fields" do
      let(:params) do
        {
          fields: "id,text,timestamp"
        }
      end

      let!(:request) do
        stub_request(:get, "https://graph.threads.net/v1.0/11111111111111111")
          .with(query: params.merge(access_token: "ACCESS_TOKEN"))
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      let(:thread) { client.get_thread("11111111111111111", **params) }

      it "returns a response object with the specified fields" do
        expect(thread.id).to eq("11111111111111111")
        expect(thread.text).to eq("Hello, world!")
        expect(thread.timestamp).to eq("2024-06-18T01:23:45Z")
        expect(thread.created_at).to eq(Time.utc(2024, 6, 18, 1, 23, 45))
      end
    end
  end

  describe "#create_thread" do
    let(:response_body) do
      {id: "11111111111111111"}.to_json
    end

    let(:params) { {text: "Hello, world!"} }
    let!(:request) do
      stub_request(:post, "https://graph.threads.net/v1.0/me/threads")
        .with(body: {access_token: "ACCESS_TOKEN", media_type: "TEXT", text: "Hello, world!"})
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:pending_thread) { client.create_thread(**params) }

    it "returns a response object with the pending thread's ID" do
      expect(pending_thread.id).to eq("11111111111111111")
    end

    it "raises an error when the text is missing" do
      params.delete(:text)

      expect { pending_thread }.to raise_error(ArgumentError, "The `:text` option is required when the post's type is \"TEXT\"")
    end

    it "raises an error when the type is invalid" do
      params[:type] = "CAROUSEL"

      expect { pending_thread }.to raise_error(ArgumentError, "Invalid post type: CAROUSEL. Must be one of: \"TEXT\", \"IMAGE\", or \"VIDEO\"")
    end

    context "when uploading an image" do
      let(:params) do
        {
          text: "Hello, world!",
          type: "IMAGE",
          image_url: "https://www.threads.net/image.jpg"
        }
      end

      let!(:request) do
        stub_request(:post, "https://graph.threads.net/v1.0/me/threads")
          .with(body: {access_token: "ACCESS_TOKEN", media_type: "IMAGE", text: "Hello, world!", image_url: "https://www.threads.net/image.jpg"})
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      it "returns a response object with the new thread's ID" do
        expect(pending_thread.id).to eq("11111111111111111")
      end

      it "raises an error when the image URL is missing" do
        params.delete(:image_url)

        expect { pending_thread }.to raise_error(ArgumentError, "The `:image_url` option is required when the post's type is \"IMAGE\"")
      end
    end

    context "when uploading a video" do
      let(:params) do
        {
          text: "Hello, world!",
          type: "VIDEO",
          video_url: "https://www.threads.net/video.mp4"
        }
      end

      let!(:request) do
        stub_request(:post, "https://graph.threads.net/v1.0/me/threads")
          .with(body: {access_token: "ACCESS_TOKEN", media_type: "VIDEO", text: "Hello, world!", video_url: "https://www.threads.net/video.mp4"})
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      it "returns a response object with the new thread's ID" do
        expect(pending_thread.id).to eq("11111111111111111")
      end

      it "raises an error when the video URL is missing" do
        params.delete(:video_url)

        expect { pending_thread }.to raise_error(ArgumentError, "The `:video_url` option is required when the post's type is \"VIDEO\"")
      end
    end
  end

  describe "#get_thread_status" do
    let(:response_body) do
      {
        id: "11111111111111111",
        status: "ERROR",
        error_message: "FAILED_PROCESSING_VIDEO"
      }.to_json
    end

    let!(:request) do
      stub_request(:get, "https://graph.threads.net/v1.0/11111111111111111")
        .with(query: {access_token: "ACCESS_TOKEN", fields: "id,status,error_message"})
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:pending_thread) { client.get_thread_status("11111111111111111") }

    it "returns a response object with the thread's status and error message" do
      expect(pending_thread.id).to eq("11111111111111111")
      expect(pending_thread.status).to eq("ERROR")
      expect(pending_thread).to be_errored
      expect(pending_thread.error_message).to eq("FAILED_PROCESSING_VIDEO")
    end
  end

  describe "#create_carousel_item" do
    let(:response_body) do
      {id: "11111111111111111"}.to_json
    end

    let(:params) { {} }

    let(:pending_thread) { client.create_carousel_item(**params) }

    it "raises an error when the type is invalid" do
      params[:type] = "TEXT"

      expect { pending_thread }.to raise_error(ArgumentError, "Invalid item type: TEXT. Must be \"IMAGE\" or \"VIDEO\"")
    end

    context "when uploading an image" do
      let(:params) do
        {
          type: "IMAGE",
          image_url: "https://www.threads.net/image.jpg"
        }
      end

      let!(:request) do
        stub_request(:post, "https://graph.threads.net/v1.0/me/threads")
          .with(body: {access_token: "ACCESS_TOKEN", media_type: "IMAGE", image_url: "https://www.threads.net/image.jpg", is_carousel_item: true})
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      let(:pending_thread) { client.create_carousel_item(**params) }

      it "returns a response object with the new thread's ID" do
        expect(pending_thread.id).to eq("11111111111111111")
      end

      it "raises an error when the image URL is missing" do
        params.delete(:image_url)

        expect { pending_thread }.to raise_error(ArgumentError, "The `:image_url` option is required when the item's type is \"IMAGE\"")
      end
    end

    context "when uploading a video" do
      let(:params) do
        {
          type: "VIDEO",
          video_url: "https://www.threads.net/video.mp4"
        }
      end

      let!(:request) do
        stub_request(:post, "https://graph.threads.net/v1.0/me/threads")
          .with(body: {access_token: "ACCESS_TOKEN", media_type: "VIDEO", video_url: "https://www.threads.net/video.mp4", is_carousel_item: true})
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      it "returns a response object with the new thread's ID" do
        expect(pending_thread.id).to eq("11111111111111111")
      end

      it "raises an error when the video URL is missing" do
        params.delete(:video_url)

        expect { pending_thread }.to raise_error(ArgumentError, "The `:video_url` option is required when the item's type is \"VIDEO\"")
      end
    end
  end

  describe "#create_carousel_thread" do
    let(:response_body) do
      {id: "11111111111111111"}.to_json
    end

    let(:params) { {children: ["22222222222222222", "33333333333333333"], text: "Check out these pics!"} }
    let!(:request) do
      stub_request(:post, "https://graph.threads.net/v1.0/me/threads")
        .with(body: {access_token: "ACCESS_TOKEN", media_type: "CAROUSEL", text: "Check out these pics!", children: "22222222222222222,33333333333333333"})
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:pending_thread) { client.create_carousel_thread(**params) }

    it "returns a response object with the new thread's ID" do
      expect(pending_thread.id).to eq("11111111111111111")
    end

    it "raises an error when the children is nil" do
      params[:children] = nil

      expect { pending_thread }.to raise_error(ArgumentError, "At least one item must be present in the `:children` option")
    end

    it "raises an error when the children is an empty array" do
      params[:children] = []

      expect { pending_thread }.to raise_error(ArgumentError, "At least one item must be present in the `:children` option")
    end

    it "raises an error when the children is an empty string" do
      params[:children] = ""

      expect { pending_thread }.to raise_error(ArgumentError, "At least one item must be present in the `:children` option")
    end
  end

  describe "#publish_thread" do
    let(:response_body) do
      {id: "11111111111111111"}.to_json
    end

    let!(:request) do
      stub_request(:post, "https://graph.threads.net/v1.0/me/threads_publish")
        .with(body: {access_token: "ACCESS_TOKEN", creation_id: "11111111111111111"})
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:thread) { client.publish_thread("11111111111111111") }

    it "returns a response object with the thread's ID" do
      expect(thread.id).to eq("11111111111111111")
    end
  end
end
