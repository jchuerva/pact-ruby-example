# encoding: utf-8
require 'rake'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

$:.unshift 'lib'

desc 'Run the client'
task :run_client do
  require 'consumer'
  require 'ap'
  ap Consumer.new.load_producer_json
end