module Furnace
  class SSA::GenericType < SSA::Type
    def parameters
      nil
    end

    def ==(other)
      other.instance_of?(self.class) &&
          other.parameters == parameters
    end

    def hash
      [self.class, parameters].hash
    end
  end
end