# encoding: utf-8
require 'rake'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

$:.unshift 'lib'

desc 'Run the client'
task :run_client do
  require 'client'
  require 'ap'
  ap Client.new.load_producer_json
end