require 'bundler/gem_tasks'
require 'bundler/setup'

task :default => :test

desc "Run test suite"
task :test do
  sh "bacon test/*_test.rb"
end

PAGES_REPO = 'git@github.com:whitequark/furnace'

desc "Build and deploy documentation to GitHub pages"
task :pages do
  system "git clone #{PAGES_REPO} gh-temp/ -b gh-pages; rm gh-temp/* -rf; touch gh-temp/.nojekyll" or abort
  system "yardoc -o gh-temp/; cp gh-temp/frames.html gh-temp/index.html; sed s,index.html,_index.html, -i gh-temp/index.html" or abort
  system "cd gh-temp/; git add -A; git commit -m 'Updated pages.'; git push -f origin gh-pages" or abort
  FileUtils.rm_rf 'gh-temp'
end
