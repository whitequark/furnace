module Furnace::Transform
end

require "furnace/transform/pipeline"

require "furnace/transform/rubinius/ast_build"
require "furnace/transform/rubinius/ast_normalize"

require "furnace/transform/generic/label_normalize"
require "furnace/transform/generic/cfg_build"
require "furnace/transform/generic/cfg_normalize"
require "furnace/transform/generic/anf_build"

require "furnace/transform/optimizing/fold_constants"