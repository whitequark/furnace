require "furnace/version"

require "furnace/ast"
require "furnace/cfg"

require "furnace/anf/node"
require "furnace/anf/edge"
require "furnace/anf/let_node"
require "furnace/anf/in_node"
require "furnace/anf/if_node"
require "furnace/anf/return_node"
require "furnace/anf/graph"

require "furnace/transform"

require "furnace/graphviz"

if RUBY_ENGINE != "rbx"
  raise "Sorry, Furnace only works on Rubinius."
end