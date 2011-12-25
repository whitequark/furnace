require "furnace/version"

require "set"

require "furnace/ast/node"
require "furnace/ast/visitor"
require "furnace/ast/pipeline"

require "furnace/cfg/node"
require "furnace/cfg/edge"
require "furnace/cfg/graph"

require "furnace/transform/rubinius/opcode"
require "furnace/transform/rubinius/normalize"

require "furnace/transform/generic/label_normalize"
require "furnace/transform/generic/cfg_build"
require "furnace/transform/generic/cfg_normalize"

if RUBY_ENGINE != "rbx"
  raise "Sorry, Furnace only works on Rubinius."
end