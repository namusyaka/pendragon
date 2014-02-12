require File.expand_path('../../lib/howl-router', __FILE__)
$:.unshift(File.dirname(__FILE__))
require 'helper'

describe Howl do
  setup{ @howl = howl }

  describe "normal routing" do
    before(:each){ @howl.reset! }

    should "basic route" do
      @howl.add(:get, "/"){ "index" }
      @howl.add(:get, "/users"){ "users" }
      get("/")
      assert_equal "index", body
      get("/users")
      assert_equal "users", body
    end

    should "ignore trailing delimiters for basic route" do
      @howl.add(:get, "/"){ "index" }
      @howl.add(:get, "/users"){ "users" }

      get("")
      assert_equal "index", body
      get("/users/")
      assert_equal "users", body
    end

    should "use pattern" do
      @howl.add(:get, "/:id"){|params| "show #{params[:id]}" }
      @howl.add(:get, "/:id.:ext"){|params| "show #{params[:id]}.#{params[:ext]}" }

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
      id_route = @howl.add(:get, "/:id"){|params| "show #{params[:id]}" }
      id_route.capture[:id] = /\d+/

      id_with_ext_route = @howl.add(:get, "/:id.:ext"){|params| "show #{params[:id]}.#{params[:ext]}" }
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
      @howl.get("/"){ "get" }
      @howl.post("/"){ "post" }
      @howl.delete("/"){ "delete" }
      @howl.put("/"){ "put" }
      @howl.head("/"){  }
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
  end
  describe "regexp routing" do
    before(:each){ @howl.reset! }

    should "basic route of regexp" do
      @howl.add(:get, /\/(\d+)/){|params| params[:captures].join(",") }
      @howl.add(:get, /\/(foo|bar)(baz)?/){|params| params[:captures].compact.join(",") }

      get("/123")
      assert_equal "123", body
      get("/foo")
      assert_equal "foo", body
      get("/foobaz")
      assert_equal "foo,baz", body
    end
  end

  describe "generate path" do
    before(:each){ @howl.reset! }

    should "basic route" do
      index = @howl.add(:get, "/", :name => :index){}
      foo_bar = @howl.add(:post, "/foo/bar", :name => :foo_bar){}
      users = @howl.add(:get, "/users/:user_id", :name => :users){}

      assert_equal @howl.path(:index), "/"
      assert_equal @howl.path(:foo_bar), "/foo/bar"
      assert_equal @howl.path(:users, :user_id => 1), "/users/1"
      assert_equal @howl.path(:users, :user_id => 1, :query => "string"), "/users/1?query=string"
    end

    should "regexp" do
      index = @howl.add(:get, /.+?/, :name => :index){}
      foo_bar = @howl.add(:post, /\d+/, :name => :foo_bar){}

      assert_equal @howl.path(:index), /.+?/
      assert_equal @howl.path(:foo_bar), /\d+/
    end
  end

  describe "#new allows block" do
    should "#new support for block." do
      @app = Howl.new do
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
end
