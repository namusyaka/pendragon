# Howl Router

[![Build Status](https://travis-ci.org/namusyaka/howl-router.png)](https://travis-ci.org/namusyaka/howl-router)

A http router for Rack and Padrino.

Howl works only in Ruby2.0.

## Installation

add this line to your Gemfile.

`gem 'howl-router'`

or

`$ gem install howl-router`

## Example

Write this code to your config.ru.

```ruby
require 'howl-router'

howl = Howl.new
howl.add(:get, "/") do
  "get"
end

howl.add(:post, "/") do
  "post"
end

howl.add(:get, "/users/:user_id") do |params|
  params.inspect
end

run howl
```

## Normal path

### Base

```ruby
howl = Howl.new

howl.add(:get, "/") do
  "hello"
end
```

### Regexp

```ruby
howl = Howl.new

howl.add(:get, /(\d+)/) do
  "hello"
end
```

### Params

```ruby
howl = Howl.new

howl.add(:get, "/users/:name") do |params|
  "hello #{params[:name]}"
end

howl.add(:get, /\/page\/(.+?)/) do |params|
  "show #{params[:captures]}"
end
```

### Captures

```ruby
howl = Howl.new

users = howl.add(:get, "/users/:name") do |params|
  "hello #{params[:name]}"
end
users.captures[:name] = /\d+/
```

### Name and Path

```ruby
howl = Howl.new

users = howl.add(:get, "/users/:name") do |params|
  "hello #{params[:name]}"
end
users.name = :users

howl.path(:users, :name => "howl") #=> "/users/howl"
```

## with Padrino

If you use Howl, your application does not use http_router.

```ruby
require 'howl-router/padrino'

class App < Padrino::Application
  register Howl::Padrino

  get :index do
    "hello howl!"
  end

  get :users, :map => "/users/:user_id/", :user_id => /\d+/ do |user_id|
    params.inspect
  end

  get :user_items, :map => "/users/:user_id/:item_id", :user_id => /\d+/, :item_id => /[1-9]+/ do |user_id, item_id|
    "Show #{user_id} and #{item_id}"
  end
end
```

## Contributing

1. fork the project.
2. create your feature branch. (`git checkout -b my-feature`)
3. commit your changes. (`git commit -am 'commit message'`)
4. push to the branch. (`git push origin my-feature`)
5. send pull request.

## License

the MIT License
