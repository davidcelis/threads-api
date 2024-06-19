# frozen_string_literal: true

require "spec_helper"

RSpec.describe Threads::API::Client do
  let(:client) { described_class.new("ACCESS_TOKEN") }

  describe "#threads" do
    let(:before_cursor) { "QVFIUkFyUFVVczIwWjVNaDVieUxHbW9vWFVqNkh0MHU0cFZARVHRTR3ZADSUxnaTdTdXl2eXBqUG4yX0RLVTF3TUszWW1nXzVJcmU5bnd2QmV2ZAVVDNVFXcFRB" }
    let(:after_cursor) { "QVFIUkZA4QzVhQW1XdTFibU9lRUF2YUR1bEVRQkhVZAWRCX2d3TThUMGVoQ3ZAwT1E4bElEa0JzNGJqV2ZAtUE00U0dMTnhZAdXpBUWN3OUdVSF9aSGZAhYXlGSDFR" }
    let(:response_body) do
      {
        data: [
          {id: "11111111111111111"},
          {id: "22222222222222222"},
          {id: "33333333333333333"}
        ],
        paging: {cursors: {before: before_cursor, after: after_cursor}}
      }.to_json
    end

    let(:params) { {} }
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/v1.0/me/threads")
        .with(query: params.merge(access_token: "ACCESS_TOKEN"))
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:response) { client.list_threads(**params) }

    it "returns a response object with threads and cursors for pagination" do
      expect(response.threads.map(&:id)).to match_array(%w[11111111111111111 22222222222222222 33333333333333333])
      expect(response.before).to eq(before_cursor)
      expect(response.after).to eq(after_cursor)
    end

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

      it "fully hydrates each Thread" do
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
    end
  end

  describe "#thread" do
    let(:response_body) do
      {id: "11111111111111111"}.to_json
    end

    let(:params) { {} }
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/v1.0/me/threads/11111111111111111")
        .with(query: params.merge(access_token: "ACCESS_TOKEN"))
        .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
    end

    let(:thread) { client.get_thread("11111111111111111") }

    it "returns a response object with a single thread" do
      expect(thread.id).to eq("11111111111111111")
    end

    context "when requesting all fields" do
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

      let(:params) do
        {
          fields: "id,media_product_type,media_type,media_url,permalink,owner,username,text,timestamp,shortcode,thumbnail_url,children,is_quote_post"
        }
      end

      let!(:request) do
        stub_request(:get, "https://graph.threads.net/v1.0/1234567890/threads/11111111111111111")
          .with(query: params.merge(access_token: "ACCESS_TOKEN"))
          .to_return(body: response_body, headers: {"Content-Type" => "application/json"})
      end

      let(:thread) { client.get_thread("11111111111111111", user_id: "1234567890", **params) }

      it "fully hydrates the Thread" do
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
    end
  end
end
