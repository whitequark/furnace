# Furnace is a set of tools for writing compilers, translators or
# static analyzers--any programs which read, manipulate or transform
# other programs.
#
# Currently it provides three independent modules, grouped by the main
# data structure being used:
#
#  * Abstract syntax trees: {AST}
#  * Static single assignment representation: {SSA}
#  * Transformations: {Transform}
#
# Additionally, a simple {Graphviz} adapter is provided.
module Furnace
  require "furnace/version"

  require "furnace/ast"
  require "furnace/ssa"

  require "furnace/transform/pipeline"
  require "furnace/transform/iterative"

  require "furnace/graphviz"
end