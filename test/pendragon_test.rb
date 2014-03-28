require File.expand_path('../../lib/pendragon', __FILE__)
$:.unshift(File.dirname(__FILE__))
require 'helper'

describe Pendragon do
  setup{ @pendragon = pendragon }

  describe "normal routing" do
    before(:each){ @pendragon.reset! }

    should "basic route" do
      @pendragon.add(:get, "/"){ "index" }
      @pendragon.add(:get, "/users"){ "users" }
      get("/")
      assert_equal "index", body
      get("/users")
      assert_equal "users", body
    end

    should "ignore trailing delimiters for basic route" do
      @pendragon.add(:get, "/"){ "index" }
      @pendragon.add(:get, "/users"){ "users" }

      get("")
      assert_equal "index", body
      get("/users/")
      assert_equal "users", body
    end

    should "use pattern" do
      @pendragon.add(:get, "/:id"){|params| "show #{params[:id]}" }
      @pendragon.add(:get, "/:id.:ext"){|params| "show #{params[:id]}.#{params[:ext]}" }

      get("/1")
      assert_equal "show 1", body
      get(URI.escape("/あいうえお"))
      assert_equal "show あいうえお", body
      get("/foo")
      assert_equal "show foo", body
      get("/1.json")
      assert_equal "show 1.json", body
      get("/foo.xml")
      assert_equal "show foo.xml", body
    end

    should "use capture" do
      id_route = @pendragon.add(:get, "/:id"){|params| "show #{params[:id]}" }
      id_route.capture[:id] = /\d+/

      id_with_ext_route = @pendragon.add(:get, "/:id.:ext"){|params| "show #{params[:id]}.#{params[:ext]}" }
      id_with_ext_route.capture[:id]  = /(foo|bar)/
      id_with_ext_route.capture[:ext] = %w[html json]

      get("/1")
      assert_equal "show 1", body
      get("/foo")
      assert_equal "Not Found", body
      get("/foo.json")
      assert_equal "show foo.json", body
      get("/baz.json")
      assert_equal "Not Found", body
      get("/foo.html")
      assert_equal "show foo.html", body
      get("/foo.xml")
      assert_equal "Not Found", body
    end

    should "support verb methods" do
      @pendragon.get("/"){ "get" }
      @pendragon.post("/"){ "post" }
      @pendragon.delete("/"){ "delete" }
      @pendragon.put("/"){ "put" }
      @pendragon.head("/"){  }
      get("/")
      assert_equal "get", body
      post("/")
      assert_equal "post", body
      delete("/")
      assert_equal "delete", body
      put("/")
      assert_equal "put", body
      head("/")
      assert_equal "", body
    end

    should "support for correct options" do
      named_route = @pendragon.get("/name/:name", name: :named_route){}
      incorrect_route = @pendragon.get("/router", router: :incorrect!){}
      status_route = @pendragon.get("/router", status: 200){}
      assert_equal named_route.name, :named_route
      assert_equal @pendragon.path(:named_route, name: :foo), "/name/foo"
      assert_equal incorrect_route.instance_variable_get(:@router).instance_of?(Pendragon::Router), true
    end

    should "allow to throw :pass for routing like journey" do
      foo = nil
      @pendragon.get("/"){ foo = "yay"; throw :pass }
      @pendragon.get("/"){ foo }
      get "/"
      assert_equal "yay", body
    end
  end

  describe "route options" do
    should "support for :capture option" do
      capture = {foo: /\d+/, bar: "bar"}
      route = @pendragon.get("/:foo/:bar", capture: capture){}
      assert_equal route.capture, capture
      assert_equal route.match("/foo/bar"), nil
      assert_equal route.match("/123/baz"), nil
      assert_equal route.match("/123/bar").instance_of?(MatchData), true
    end

    should "support for :name option" do
      route = @pendragon.get("/name/:name", name: :named_route){}
      assert_equal route.name, :named_route
      assert_equal @pendragon.path(:named_route, name: :foo), "/name/foo"
    end

    should "not support for :router option" do
      route = @pendragon.get("/router", router: :incorrect!){}
      assert_equal route.instance_variable_get(:@router).instance_of?(Pendragon::Router), true
    end

    should "support for :order option" do
      @pendragon.get("/", order: 2){ "three" }
      @pendragon.get("/", order: 0){ "one" }
      @pendragon.get("/", order: 1){ "two" }
      request = Rack::MockRequest.env_for("/")
      assert_equal @pendragon.recognize(request).map{|route, _| route.call }, ["one", "two", "three"]
    end

    should "support for :status option" do
      @pendragon.get("/", status: 201){ "hey" }
      get "/"
      assert_equal 201, status
    end

    should "support for :header option" do
      header = {"Content-Type" => "text/plain;"}
      @pendragon.get("/", header: header){ "hey" }
      get "/"
      assert_equal header.merge("Content-Length" => "3"), headers
    end
  end

  describe "regexp routing" do
    before(:each){ @pendragon.reset! }

    should "basic route of regexp" do
      @pendragon.add(:get, /\/(\d+)/){|params| params[:captures].join(",") }
      @pendragon.add(:get, /\/(foo|bar)(baz)?/){|params| params[:captures].compact.join(",") }

      get("/123")
      assert_equal "123", body
      get("/foo")
      assert_equal "foo", body
      get("/foobaz")
      assert_equal "foo,baz", body
    end
  end

  describe "generate path" do
    before(:each){ @pendragon.reset! }

    should "basic route" do
      index = @pendragon.add(:get, "/", :name => :index){}
      foo_bar = @pendragon.add(:post, "/foo/bar", :name => :foo_bar){}
      users = @pendragon.add(:get, "/users/:user_id", :name => :users){}

      assert_equal @pendragon.path(:index), "/"
      assert_equal @pendragon.path(:foo_bar), "/foo/bar"
      assert_equal @pendragon.path(:users, :user_id => 1), "/users/1"
      assert_equal @pendragon.path(:users, :user_id => 1, :query => "string"), "/users/1?query=string"
    end

    should "regexp" do
      index = @pendragon.add(:get, /.+?/, :name => :index){}
      foo_bar = @pendragon.add(:post, /\d+/, :name => :foo_bar){}

      assert_equal @pendragon.path(:index), /.+?/
      assert_equal @pendragon.path(:foo_bar), /\d+/
    end
  end

  describe "#new allows block" do
    should "#new support for block." do
      @app = Pendragon.new do
        foo = add(:get, "/", :name => :foo){"foo"}
        bar = add(:post, "/", :name => :bar){"bar"}
      end
      get("/")
      assert_equal "foo", body
      post("/")
      assert_equal "bar", body
      assert_equal @app.path(:foo), "/"
      assert_equal @app.path(:bar), "/"
    end
  end

  describe "header" do
    should "set Allow header when occur 405" do
      @pendragon.get("/"){}
      @pendragon.put("/"){}
      post "/"
      assert_equal response.header['Allow'], "GET, PUT"
    end
  end
end
