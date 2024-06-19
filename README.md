# Threads API

`threads-api` is a Ruby client for [Threads](https://developers.facebook.com/docs/threads), providing a simple interface for interacting with its API endpoints after the OAuth2 handshake is initialized.

## Installation

Install the gem and add it to your application's Gemfile by executing:

```sh
$ bundle add threads-api
```

If your'e not using bundler to manage your dependencies, you can install the gem manually:

```sh
$ gem install threads-api
```

## Usage

The Threads API uses OAuth2 for authentication. While this client won't initialize the handshake for you (which requires a web server to direct the user to Facebook and accept a callback), it will allow you to _finish_ the handshake by exchanging the OAuth2 code from your callback for an access token:

```ruby
client = Threads::API::OAuth2::Client.new(client_id: ENV["THREADS_CLIENT_ID"], client_secret: ENV["THREADS_CLIENT_SECRET"])
response = client.access_token(code: params[:code], redirect_uri: "https://example.com/threads/oauth/callback")

# Save the access token and user ID for future requests.
access_token = response.access_token
user_id = response.user_id
```

The access token returned by this initial exchange is short-lived and only valid for one hour. You can exchange it for a long-lived access token by calling `exchange_access_token`:

```ruby
response = client.exchange_access_token(access_token)

# Save the long-lived access token for future requests.
access_token = response.access_token
expires_at = Time.now + response.expires_in
```

Long-lived access tokens are valid for 60 days. After one day (but before the token expires), you can refresh them by calling `refresh_access_token`:

```ruby
response = client.refresh_access_token(access_token)

# Save the refreshed access token for future requests.
access_token = response.access_token
expires_at = Time.now + response.expires_in
```

Once you have a valid access token, whether it's short-lived or long-lived, you can use it to make requests to the Threads API.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidcelis/threads-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/davidcelis/threads-api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `threads-api` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/davidcelis/threads-api/blob/main/CODE_OF_CONDUCT.md).
