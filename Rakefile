require 'bundler/gem_tasks'
require 'bundler/setup'

task :default => :test

task :test do
  require 'bacon'
  Bacon.summary_at_exit
  Dir["test/**/*_test.rb"].each do |file|
    load file
  end
end