# Pendragon

[![Build Status](https://travis-ci.org/namusyaka/pendragon.png)](https://travis-ci.org/namusyaka/pendragon) [![Gem Version](https://badge.fury.io/rb/pendragon.png)](http://badge.fury.io/rb/pendragon)

Pendragon provides an HTTP router for use in Rack and Padrino. 
As a Rack application, makes it easy to define the complicated routing.
As a Padrino plugin, your application uses Pendragon instead of http_router. 
Therefore, some bugs of http_router will be fixed.

*If you want to use in Ruby1.9, you can do it by using [mustermann/1.9-support branch](https://github.com/rkh/mustermann/tree/1.9-support).*

```ruby
Pendragon.new do
  get("/"){ "hello world" }
  get("/foo/:bar", name: :foo) do |params|
    "foo is #{params[:bar]}"
  end
end
```

## Installation

Depends on [rack](https://github.com/rack/rack) and [mustermann](https://github.com/rkh/mustermann).

`gem install pendragon`

## Usage

### Configuration

|name            |types  |default|description               |
|:---------------|:------|:------|:-------------------------|
|enable_compiler |boolean|false|The performance will be improved. However, it will increase the first load time.|
|auto_rack_format|boolean|true|If disable this param, the block of route should return the response of valid rack format.|

#### `enable_compiler`

```ruby
# Performance will be improved!
Pendragon.configure do |config|
  config.enable_compiler = true
end
```

*The compiler mode was inspired by [rack-multiplexer](https://github.com/r7kamura/rack-multiplexer). Thank you!*

#### `auto_rack_format`

```ruby
Pendragon.configure do |config|
  config.auto_rack_format = false
end
# Enable the param (default)
Pendragon.new do
  get("/"){ "hey" }
end

# Disable the param
Pendragon.new do
  get("/"){ [200, {"Content-Type" => "text/html;charset=utf-8"}, ["hey"]] }
end
```

### Register the route

It has some methods to register a route. For example, `#get`, `#post` and `#delete` are so.
This section introduces all those methods.

#### `add(verb, path, option, &block)`

The method is the basis of the registration method of all.
In comparison with other registration methods, one argument is increased.

```ruby
Pendragon.new do
  # The two approach have the same meaning.
  add(:get, "/"){ "hello world" }
  get("/"){ "hello world" }
end
```

#### `get(path, option, &block)`, `post`, `delete`, `put` and `head`

Basically the usage is the same with `#add`.
You may as well use those methods instead of `#add` because those methods are easy to understand.

```ruby
Pendragon.new do
  get("/"){ "hello world" }
  post("/"){ "hello world" }
  delete("/"){ "hello world" }
  put("/"){ "hello world" }
  head("/"){ "hello world" }
end
```

##### Path

The path must be an instance of String (this must be complied with the Mustermann::Sinatra's rule) or Regexp.

##### Route options

|name|types   |description               |
|:----|:------|:-------------------------|
|name |symbol |specify the name of route for `Pendragon::Router#path` method.|
|order|integer|specify the order for the prioritized routes.|
|capture|hash|specify the capture for matching condition. [more information here](https://github.com/rkh/mustermann)|

##### Block Parameters

The block is allowed to pass a parameter.
It will be an instance of Hash.

```ruby
pendragon = Pendragon.new do
  get("/:id/:foo/:bar"){|params| params.inspect }
end

request = Rack::MockRequest.env_for("/123/hey/ho")
pendragon.recognize(request).first.call #=> '{id: "123", foo: "hey", bar: "ho"}'
```

### Recognize the route

The route registered can be recognized by several methods.

#### `recognize(request)`

This method returns all the routes that match the conditions.
The format of returns will be such as `[[Pendragon::Route, params], ...]`.
The request must be an instance of `Rack::Request` or Hash created by `Rack::MockRequest.env_for`.

```ruby
pendragon = Pendragon.new
index = pendragon.get("/"){ "hello world" }
foo   = pendragon.get("/foo/:bar"){ "foo is bar" }

mock_request = Rack::MockRequest.env_for("/")
route, params = pendragon.recognize(mock_request).first

route.path == index.path #=> true
params #=> {}

mock_request = Rack::MockRequest.env_for("/foo/baz")
route, params = pendragon.recognize(mock_request).first

route.path == foo.path #=> true
params #=> {bar: "baz"}
```

#### `recognize_path(path_info)`

Recognizes a route from `path_info`.
The method uses `#recognize`, but return value is not same with it.
Maybe this is useful if you set the name to the route.

```ruby
pendragon = Pendragon.new do
  get("/", name: :index){ "hello world" }
  get("/:id", name: :foo){ "fooooo" }
end

pendragon.recognize_path("/") #=> [:index, {}]
pendragon.recognize_path("/hey") #=> [:foo, {id: "hey"}]
```

#### `path(name, *args)`

Recognizes a route from route's name, and expands the path from parameters.
If you pass a name that does not exist, Pendragon raises `InvalidRouteException`.
The parameters that is not required to expand will be treated as query.

```ruby
pendragon = Pendragon.new do
  get("/", name: :index){ "hello world" }
  get("/:id", name: :foo){ "fooooo" }
end

pendragon.path(:index) #=> "/"
pendragon.path(:foo, id: "123") #=> "/123"
pendragon.path(:foo, id: "123", bar: "hey") #=> "/123?bar=hey"
```

### Prioritized Routes

Pendragon supports for respecting route order.
If you want to use this, you should pass the `:order` option to the registration method.

```ruby
pendragon = Pendragon.new do
  get("/", order: 1){ "two" }
  get("/", order: 0){ "one" }
  get("/", order: 2){ "three" }
end

request = Rack::MockRequest.env_for("/")
pendragon.recognize(request).map{|route, _| route.call } #=> ["one", "two", "three"]
```

### With Padrino

Add `register Pendragon::Padrino` to your padrino application.
Of course, Pendragon has compatibility with Padrino Routing.


```ruby
require 'pendragon/padrino'

class App < Padrino::Application
  register Pendragon::Padrino
  
  ##
  # Also, your app's performance will be improved by using compiler mode.
  # Pendragon.configure do |config|
  #   config.enable_compiler = true
  # end

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
