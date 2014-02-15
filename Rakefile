require 'rake'
require 'rake/testtask'
require 'pendragon'

Rake::TestTask.new(:test_without_compiler) do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/*_test.rb']
  test.verbose = true
end

Rake::TestTask.new(:test_with_compiler) do |test|
  test.libs << 'test'
  test.ruby_opts = ["-r compile_helper.rb"]
  test.test_files = Dir['test/**/*_test.rb']
  test.verbose = true
end

task :test => [:test_without_compiler, :test_with_compiler]
task :default => :test
