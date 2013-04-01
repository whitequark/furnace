# Furnace is a set of tools for writing compilers, translators or
# static analyzers--any programs which read, manipulate or transform
# other programs.
#
# Currently it provides three loosely coupled modules, each operating
# upon a single kind of entity:
#
#  * Transformations: {Transform}
#  * Parametric types: {Type}
#  * Static single assignment representation: {SSA}
#
# Additionally, a custom pretty printing module {AwesomePrinter} is
# provided which has built-in knowledge of {Type}s.
#
# See also the [AST gem](http://rubygems.org/gems/ast).
#
module Furnace
  require "furnace/version"

  require "furnace/awesome_printer"

  require "furnace/type"
  require "furnace/ssa"

  require "furnace/transform/pipeline"
  require "furnace/transform/iterative"
end
