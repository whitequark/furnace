require "furnace/version"

require "set"

require "furnace/ast/node"
require "furnace/ast/symbolic_node"
require "furnace/ast/visitor"

require "furnace/cfg/node"
require "furnace/cfg/edge"
require "furnace/cfg/graph"

require "furnace/anf/node"
require "furnace/anf/edge"
require "furnace/anf/let_node"
require "furnace/anf/in_node"
require "furnace/anf/if_node"
require "furnace/anf/return_node"
require "furnace/anf/graph"

require "furnace/transform/pipeline"

require "furnace/transform/rubinius/ast_build"
require "furnace/transform/rubinius/ast_normalize"

require "furnace/transform/generic/label_normalize"
require "furnace/transform/generic/cfg_build"
require "furnace/transform/generic/cfg_normalize"
require "furnace/transform/generic/anf_build"

require "furnace/transform/optimizing/fold_constants"

require "furnace/graphviz"

if RUBY_ENGINE != "rbx"
  raise "Sorry, Furnace only works on Rubinius."
end