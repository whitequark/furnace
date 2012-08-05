module Furnace
end

require "furnace/version"

require "furnace/ast"
require "furnace/cfg"
require "furnace/code"

require "furnace/transform/pipeline"
require "furnace/transform/iterative_process"

require "furnace/graphviz"