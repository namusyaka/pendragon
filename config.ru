load  File.expand_path('../lib/howl-router.rb', __FILE__)

howl = Howl.new

howl.add(:get, "/") do
  "hello world !"
end

run howl
