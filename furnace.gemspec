# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "furnace/version"

Gem::Specification.new do |s|
  s.name        = "furnace"
  s.version     = Furnace::VERSION
  s.authors     = ["Peter Zotov"]
  s.email       = ["whitequark@whitequark.org"]
  s.homepage    = "http://github.com/whitequark/furnace"
  s.summary     = %q{A static Ruby compiler}
  s.description = %q{Furnace aims to compile Ruby code into small static } <<
                  %q{executables by restricting its metaprogramming features.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
