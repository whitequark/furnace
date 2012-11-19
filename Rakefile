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

PAGES_REPO = 'git@github.com:whitequark/furnace'

task :pages do
  system "git clone #{PAGES_REPO} gh-temp/ -b gh-pages; rm gh-temp/* -rf" or abort
  system "yardoc -o gh-temp/; cd gh-temp/; git add -A; git commit -m 'Updated pages.'" or abort
  system "cd gh-temp/; git push -f origin gh-pages" or abort
  FileUtils.rm_rf 'gh-temp'
end