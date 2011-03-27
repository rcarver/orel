require 'bundler/setup'

require 'cucumber/rake/task'
require 'rspec/core/rake_task'

task :default => :test

desc "Run all tests"
task :test => [:spec, :cucumber]

RSpec::Core::RakeTask.new
Cucumber::Rake::Task.new
