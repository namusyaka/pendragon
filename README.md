# Pendragon

[![Build Status](https://travis-ci.org/namusyaka/pendragon.svg?branch=master)](https://travis-ci.org/namusyaka/pendragon) [![Gem Version](https://badge.fury.io/rb/pendragon.svg)](http://badge.fury.io/rb/pendragon)

Pendragon provides an HTTP router and its toolkit for use in Rack. As a Rack application, it makes it easy to define complicated routing. 
Algorithms of the router are used in [Padrino](https://github.com/padrino/padrino-framework) and [Grape](https://github.com/ruby-grape/grape), it's fast, flexible and robust.

*If you want to use in Ruby-1.9, you can do it by using [mustermann19](https://github.com/namusyaka/mustermann19).*


```ruby
Pendragon.new do
  get('/') { [200, {}, ['hello world']] }
  namespace :users do
    get('/',    to: -> { [200, {}, ['User page index']] })
    get('/:id', to: -> (id) { [200, {}, [id]] })
    get('/:id/comments') { |id| [200, {}, [User.find_by(id: id).comments.to_json]] }
  end
end
```

## Router Patterns

|Type  |Description  |Note  |
|---|---|---|
|[liner](https://github.com/namusyaka/pendragon/blob/master/lib/pendragon/liner.rb)  |Linear search, Optimized Mustermann patterns | |
|[realism](https://github.com/namusyaka/pendragon/blob/master/lib/pendragon/realism.rb)  |First route is detected by union regexps (Actually, O(1) in ruby level), routes since the first time will be retected by linear search | this algorithm is using in Grape |
|[radix](https://github.com/namusyaka/pendragon-radix)  |Radix Tree, not using Mustermann and regexp| requires C++11 |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pendragon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pendragon


## Usage

### Selects router pattern

You can select router pattern as following code.

```ruby
# Gets Linear router class by passing type in `Pendragon.[]`
Pendragon[:linear] #=> Pendragon::Linear

# Specify :type to construction of Pendragon.
Pendragon.new(type: :linear) { ... }
```

### Registers a route

It has some methods to register a route. For example, `#get`, `#post` and `#delete` are so.
This section introduces all those methods.

#### `route(method, path, **options, &block)`


The method is the basis of the registration method of all.
In comparison with other registration methods, one argument is increased.

```ruby
Pendragon.new do
  route('GET', ?/){ [200, {}, ['hello']] }
end
```

#### `get(path, **options, &block)`, `post`, `delete`, `put` and `head`

Basically the usage is the same with `#route`.
You may as well use those methods instead of `#route` because those methods are easy to understand.

```ruby
Pendragon.new do
  get   (?/) { [200, {}, ['hello']] }
  post  (?/) { [200, {}, ['hello']] }
  delete(?/) { [200, {}, ['hello']] }
  put   (?/) { [200, {}, ['hello']] }
  head  (?/) { [200, {}, ['hello']] }
end
```

### Mounts Rack Application

You can easily mount your rack application onto Pendragon.

*Please note that pendragon distinguishes between processing Proc and Rack Application.*

```ruby
class RackApp
  def call(env)
    puts env #=> rack default env
    [200, {}, ['hello']]
  end
end

Pendragon.new do
  get '/ids/:id', to: -> (id) { p id } # Block parameters are available
  get '/rack/:id', to: RackApp.new # RackApp#call will be called, `id` is not passed and `env` is passed instead.
end
```

### Halt

You can halt to processing by calling `throw :halt` inside your route.

```ruby
Pendragon.new do
  get ?/ do
    throw :halt, [404, {}, ['not found']]
    [200, {}, ['failed to halt']]
  end
end
```

### Cascading

A route can punt to the next matching route by using `X-Cascade` header.

```ruby
pendragon = Pendragon.new do
  foo = 1
  get ?/ do
    [200, { 'X-Cascade' => 'pass' }, ['']]
  end

  get ?/ do
    [200, {}, ['goal!']]
  end
end

env = Rack::MockRequest.env_for(?/)
pendragon.call(env) #=> [200, {}, ['goal!']]
```

## Contributing

1. fork the project.
2. create your feature branch. (`git checkout -b my-feature`)
3. commit your changes. (`git commit -am 'commit message'`)
4. push to the branch. (`git push origin my-feature`)
5. send pull request.

## License

the MIT License
