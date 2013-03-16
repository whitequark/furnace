module Furnace
  class Type::Value < Type::Top
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def to_s
      %{'#{@value.inspect}}
    end

    def eql?(other)
      other.instance_of?(Type::Value) &&
          other.value == @value
    end

    def hash
      [self.class, @value].hash
    end
  end
end
