module Furnace::SSA
  class Value
    attr_reader   :name
    attr_accessor :type

    def initialize(name, type=nil)
      @name = name.freeze
      @type = type
    end

    def constant?
      false
    end

    def evaluate(context)
      context.use @name
    end

    def inspect
      "#{Furnace::SSA.inspect_type type} %#{name}"
    end
  end
end