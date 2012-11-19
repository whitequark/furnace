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

task :pages do
  FileUtils.rm_rf 'gh-temp'

  system "git clone . gh-temp/ -b gh-pages; rm gh-temp/* -rf" or abort
  system "yardoc -o gh-temp/; cd gh-temp/; git add -A; git commit -m 'Updated pages.'" or abort
  system "cd gh-temp/; git push -f git@github.com:whitequark/furnace gh-pages" or abort
  FileUtils.rm_rf 'gh-temp'
end