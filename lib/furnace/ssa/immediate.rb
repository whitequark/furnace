module Furnace::SSA
  class Immediate
    attr_reader :value
    attr_reader :type

    def initialize(type, value)
      @value, @type = value, type
      freeze
    end

    def constant?
      true
    end

    def evaluate(context)
      @value
    end

    def inspect
      "#{Furnace::SSA.inspect_type @type} #{@value}"
    end
  end
end