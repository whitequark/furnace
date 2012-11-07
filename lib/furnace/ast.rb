module Furnace
  # Furnace::AST is a library for manipulating abstract syntax trees.
  #
  # It embraces immutability; each AST node is inherently frozen at
  # creation, and updating a child node requires recreating that node
  # and its every parent, recursively.
  # This is a design choice. It does create significant pressure on
  # garbage collector, but completely eliminates all concurrency
  # and aliasing problems.
  #
  # See also {Node} and {Processor} for additional
  # recommendations and design patterns.
  module AST
  end

  require_relative "ast/node"
  require_relative "ast/processor"
end