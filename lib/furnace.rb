# Furnace is a set of tools for writing compilers, translators or
# static analyzers--any programs which read, manipulate or transform
# other programs.
#
# Currently it provides four independent modules, grouped by the main
# data structure being used:
#
#  * Abstract syntax trees: {AST}
#  * Parametric types: {Type}
#  * Static single assignment representation: {SSA}
#  * Transformations: {Transform}
#
module Furnace
  require "furnace/version"

  require "furnace/ast"
  require "furnace/type"
  require "furnace/ssa"

  require "furnace/transform/pipeline"
  require "furnace/transform/iterative"
end
