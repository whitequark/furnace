require "furnace/version"

require "set"

require "furnace/ast/node"
require "furnace/ast/visitor"

require "furnace/cfg/node"
require "furnace/cfg/edge"
require "furnace/cfg/graph"

require "furnace/transform/pipeline"

require "furnace/transform/rubinius/ast_build"
require "furnace/transform/rubinius/ast_normalize"

require "furnace/transform/generic/label_normalize"
require "furnace/transform/generic/cfg_build"
require "furnace/transform/generic/cfg_normalize"
require "furnace/transform/generic/anf_build"

if RUBY_ENGINE != "rbx"
  raise "Sorry, Furnace only works on Rubinius."
end