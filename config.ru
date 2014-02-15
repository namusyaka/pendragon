load  File.expand_path('../lib/pendragon.rb', __FILE__)

pendragon = Pendragon.new

pendragon.add(:get, "/") do
  "hello world !"
end

run pendragon
