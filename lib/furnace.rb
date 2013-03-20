# Furnace is a set of tools for writing compilers, translators or
# static analyzers--any programs which read, manipulate or transform
# other programs.
#
# Currently it provides four loosely coupled modules, each operating
# upon a single kind of entity:
#
#  * Abstract syntax trees: {AST}
#  * Parametric types: {Type}
#  * Static single assignment representation: {SSA}
#  * Transformations: {Transform}
#
# Additionally, a custom pretty printing module {AwesomePrinter} is
# provided which has built-in knowledge of {Type}s.
#
module Furnace
  require "furnace/version"

  require "furnace/awesome_printer"

  require "furnace/ast"
  require "furnace/type"
  require "furnace/ssa"

  require "furnace/transform/pipeline"
  require "furnace/transform/iterative"
end
