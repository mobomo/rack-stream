# Grape Example

[Grape](https://github.com/intridea/grape) is a framework for building
REST APIs. This demo shows how to write a basic API that does pubsub via
redis.

## Setup

Install redis.

```
bundle
thin start -p 9292

curl -i -N http://localhost:9292/messages

# another window
curl -dtext="hello world" http://localhost:9292/messages
```