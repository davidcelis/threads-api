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

Once you have a valid access token, whether it's short-lived or long-lived, you can use it to make requests to the Threads API using a `Threads::API::Client`:

```ruby
client = Threads::API::Client.new(access_token)
```

## Reading Threads

To read threads for a user:

```ruby
# List recent threads for a user.
response = client.list_threads # Defaults to the authenticated user
response = client.list_threads(user_id: "7770386109746442")

# By default, the Threads API returns 25 threads at a time. You can paginate through them like so:
next_page = client.list_threads(after: response.after_cursor) # or
previous_page = client.list_threads(before: response.before_cursor)

# Get a specific thread by ID.
thread = client.get_thread("18050206876707110") # Defaults to the authenticated user
thread = client.get_thread("18050206876707110", user_id: "7770386109746442")
```

`Threads::API::Client#list_threads` accepts the following options:

* `user_id` - The ID of the user whose threads you want to read. Defaults to `"me"`, the authenticated user.
* `fields` - An Array (or comma-separated String) of fields to include in the response. By default, only `id` is requested. See the [Threads API documentation](https://developers.facebook.com/docs/threads/threads-media#fields) for a list of available fields.
* `since` - An ISO 8601 date string. Only threads published after this date will be returned.
* `until` - An ISO 8601 date string. Only threads published before this date will be returned.
* `before` - A cursor string returned by a previous request for pagination.
* `after` - A cursor string returned by a previous request for pagination.
* `limit` - The number of threads to return. Defaults to `25`, with a maximum of `100`.

`Threads::API::Client#get_thread` accepts only the `user_id` and `fields` options.

## Posting to Threads

Posting to Threads is, at the very least, a two-step process. Threads requires that you first create a container for the media you want to post, then explicitly publishing that container as a thread. However, more steps are involved if you want to post multiple media items in a single thread.

### Creating the Thread

The first step in posting to Threads is to create a "media container", even if your post is text-only.

```ruby
# Create a text-only post
client.create_thread(text: "Hello, world!")

# Create a post with a photo or video
client.create_thread(type: "IMAGE", image_url: "https://example.com/image.jpg", text: "Some optional text")
client.create_thread(type: "VIDEO", video_url: "https://example.com/video.mp4", text: "Some optional text")

# Reply to one of your own threads
client.create_thread(text: "Hello, world!", reply_to_id: "18050206876707110")

# Control who can reply to your thread. Defaults to "everyone".
client.create_thread(text: "Hello, world!", reply_control: "accounts_you_follow") # or "mentioned_only"
```

### Publishing the Thread

Once you've created a media container, you can publish it as a thread:

```ruby
pending_thread = client.create_thread(text: "Hello, world!")
client.publish_thread(pending_thread.id)
```

According to Meta, you may need to wait before attempting to publish a thread, especially if the thread contains images or videos. They suggest checking the status of the pending thread before attempting to publish it:

```ruby
pending_thread = client.create_thread(text: "Hello, world!")
pending_thread = client.get_thread_status(pending_thread.id)

while pending_thread.in_progress?
  # Wait a bit (they recommend checking only once per minute) and try again
  sleep 60
  pending_thread = client.get_thread_status(pending_thread.id)
end

if pending_thread.finished?
  client.publish_thread(pending_thread.id)
elsif pending_thread.errored?
  # Handle the error
else
  # Unpublished threads expire after 24 hours.
  pending_thread.expired?

  # If you've already published the thread, the status will be "PUBLISHED".
  pending_thread.published?
end
```

### Posting multiple photos and/or videos

Threads allows you to post a combination of up to 10 photos and/or videos in a single thread. To do so, you must first create a media container for each photo or video you want to post, then create a media container for the thread itself, and finally publish the thread.

```ruby
# Create carousel items for each photo or video you want to post
image1 = client.create_carousel_item(type: "IMAGE", image_url: "https://example.com/image1.jpg")
image2 = client.create_carousel_item(type: "IMAGE", image_url: "https://example.com/image2.jpg")
video1 = client.create_carousel_item(type: "VIDEO", video_url: "https://example.com/video1.mp4")
video2 = client.create_carousel_item(type: "VIDEO", video_url: "https://example.com/video2.mp4")

# Create the media container for the thread itself
pending_thread = client.create_carousel_thread(text: "Some optional text", children: [image1.id, image2.id, video1.id, video2.id])

# Publish the thread
client.publish_thread(pending_thread.id)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidcelis/threads-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/davidcelis/threads-api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `threads-api` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/davidcelis/threads-api/blob/main/CODE_OF_CONDUCT.md).
