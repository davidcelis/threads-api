# frozen_string_literal: true

require "spec_helper"

RSpec.describe Threads::API::OAuth2::Client do
  let(:client) { described_class.new(client_id: "CLIENT_ID", client_secret: "CLIENT_SECRET") }

  describe "#access_token" do
    let!(:request) do
      stub_request(:post, "https://graph.threads.net/oauth/access_token")
        .with(body: {
          client_id: "CLIENT_ID",
          client_secret: "CLIENT_SECRET",
          grant_type: "authorization_code",
          redirect_uri: "http://example.com/threads/oauth/callback",
          code: "CODE"
        })
        .to_return(body: {access_token: "ACCESS_TOKEN", user_id: 1234567890}.to_json, headers: {"Content-Type" => "application/json"})
    end

    let(:response) { client.access_token(code: "CODE", redirect_uri: "http://example.com/threads/oauth/callback") }

    it "returns an access token" do
      expect(response.access_token).to eq("ACCESS_TOKEN")
      expect(response.user_id).to eq(1234567890)
    end

    context "when an error occurs" do
      let!(:request) do
        stub_request(:post, "https://graph.threads.net/oauth/access_token")
          .to_return(body: {error_type: "invalid_request", error_message: "Invalid redirect URI", code: 400}.to_json, headers: {"Content-Type" => "application/json"})
      end

      it "returns an error response" do
        expect(response.error_type).to eq("invalid_request")
        expect(response.error_message).to eq("Invalid redirect URI")
        expect(response.code).to eq(400)
      end
    end
  end

  describe "#exchange_access_token" do
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/access_token")
        .with(query: {
          client_secret: "CLIENT_SECRET",
          grant_type: "th_exchange_token",
          access_token: "ACCESS_TOKEN"
        })
        .to_return(body: {access_token: "LONG_LIVED_TOKEN", token_type: "bearer", expires_in: 5184000}.to_json, headers: {"Content-Type" => "application/json"})
    end

    let(:response) { client.exchange_access_token("ACCESS_TOKEN") }

    it "returns a long-lived access token" do
      expect(response.access_token).to eq("LONG_LIVED_TOKEN")
      expect(response.token_type).to eq("bearer")
      expect(response.expires_in).to eq(5184000)
    end
  end

  describe "#refresh_access_token" do
    let!(:request) do
      stub_request(:get, "https://graph.threads.net/refresh_access_token")
        .with(query: {
          grant_type: "th_refresh_token",
          access_token: "LONG_LIVED_TOKEN"
        })
        .to_return(body: {access_token: "REFRESHED_TOKEN", token_type: "bearer", expires_in: 5184000}.to_json, headers: {"Content-Type" => "application/json"})
    end

    let(:response) { client.refresh_access_token("LONG_LIVED_TOKEN") }

    it "returns a refreshed access token" do
      expect(response.access_token).to eq("REFRESHED_TOKEN")
      expect(response.token_type).to eq("bearer")
      expect(response.expires_in).to eq(5184000)
    end
  end
end
