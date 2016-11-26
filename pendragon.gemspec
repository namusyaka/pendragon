require File.expand_path("../lib/pendragon/version", __FILE__)

Gem::Specification.new "pendragon", Pendragon::VERSION do |s|
  s.description = "Toolkit for implementing HTTP Router in Ruby"
  s.summary = <<-summary
Pendragon is toolkit for implementing HTTP router.
The router created by pendragon can be used as a rack application.
  summary
  s.authors = ["namusyaka"]
  s.email = "namusyaka@gmail.com"
  s.homepage = "https://github.com/namusyaka/pendragon"
  s.files = `git ls-files`.split("\n") - %w(.gitignore)
  s.test_files = s.files.select { |path| path =~ /^test\/.*_test\.rb/ }
  s.license = "MIT"

  s.add_dependency "rack", ">= 1.3.0"
  s.add_dependency "mustermann"
end
