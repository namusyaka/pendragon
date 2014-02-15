# Pendragon

[![Build Status](https://travis-ci.org/namusyaka/pendragon.png)](https://travis-ci.org/namusyaka/pendragon)

Provides an HTTP router for use in Rack and Padrino.

Pendragon works only in Ruby2.0.

If you want to use in Ruby1.9, you can do it by using [mustermann/1.9-support branch](https://github.com/rkh/mustermann/tree/1.9-support).

## Installation

add this line to your Gemfile.

`gem 'pendragon'`

or

`$ gem install pendragon`

## Configuration

If you enable compiler, performance will be improved at the expense of some features as below.

* Route priority will not work (Might support in the future).
* Duplicated routes will not work correctly.
* MethodNotAllowed will not work.

This implementation was inspired by [rack-multiplexer](https://github.com/r7kamura/rack-multiplexer).

```ruby
Pendragon.configure do |config|
  config.enable_compiler = true # default value is false
end
```

## Example

Write this code to your config.ru.

```ruby
require 'pendragon'

pendragon = Pendragon.new
pendragon.add(:get, "/") do
  "get"
end

pendragon.get("/hey") do
  "hey"
end

pendragon.post("/hey") do
  "hey, postman!"
end


pendragon.get("/users/:user_id") do |params|
  params.inspect
end

run pendragon
```

## Normal path

### Base

```ruby
pendragon = Pendragon.new

pendragon.add(:get, "/") do
  "hello"
end
```

### Regexp

```ruby
pendragon = Pendragon.new

pendragon.add(:get, /(\d+)/) do
  "hello"
end
```

### Params

```ruby
pendragon = Pendragon.new

pendragon.add(:get, "/users/:name") do |params|
  "hello #{params[:name]}"
end

pendragon.add(:get, /\/page\/(.+?)/) do |params|
  "show #{params[:captures]}"
end
```

### Captures

```ruby
pendragon = Pendragon.new

users = pendragon.add(:get, "/users/:name") do |params|
  "hello #{params[:name]}"
end
users.captures[:name] = /\d+/
```

### Name and Path

```ruby
pendragon = Pendragon.new

users = pendragon.add(:get, "/users/:name") do |params|
  "hello #{params[:name]}"
end
users.name = :users

pendragon.path(:users, :name => "howl") #=> "/users/howl"
```

## with Padrino

If you use Pendragon, your application does not use http_router.

```ruby
require 'pendragon/padrino'

class App < Padrino::Application
  register Pendragon::Padrino

  get :index do
    "hello pendragon!"
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
