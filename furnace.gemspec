# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "furnace/version"

Gem::Specification.new do |s|
  s.name        = "furnace"
  s.version     = Furnace::VERSION
  s.authors     = ["Peter Zotov"]
  s.email       = ["whitequark@whitequark.org"]
  s.homepage    = "http://github.com/whitequark/furnace"
  s.summary     = %q{A static code analysis framework}
  s.description = %q{Furnace is a static code analysis framework for dynamic languages, } <<
                  %q{aimed at efficient type and behavior inference.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'bacon', '~> 1.1'
end
