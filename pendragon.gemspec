require File.expand_path("../lib/pendragon/version", __FILE__)

Gem::Specification.new "pendragon", Pendragon::VERSION do |s|
  s.description = "Provides an HTTP router for use in Rack and Padrino."
  s.summary = s.description
  s.authors = ["namusyaka"]
  s.email = "namusyaka@gmail.com"
  s.homepage = "https://github.com/namusyaka/pendragon"
  s.files = `git ls-files`.split("\n") - %w(.gitignore)
  s.test_files = s.files.select { |path| path =~ /^test\/.*_test\.rb/ }
  s.license = "MIT"

  s.add_dependency "rack", ">= 1.3.0"
  s.add_dependency "mustermann", "= 0.2.0"
  s.add_development_dependency "rake", ">= 0.8.7"
  s.add_development_dependency "rack-test", ">= 0.5.0"
  s.add_development_dependency "mocha", ">= 0.10.0"
  s.add_development_dependency "haml"
  s.add_development_dependency "padrino-core", "= 0.12.0.rc3"
end
