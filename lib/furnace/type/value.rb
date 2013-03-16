module Furnace
  class Type::Value < Type::Top
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def to_s
      %{'#{@value.inspect}}
    end
  end
end
