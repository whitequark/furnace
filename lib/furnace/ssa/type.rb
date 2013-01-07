module Furnace
  class SSA::Type
    def to_type
      self
    end

    def monotype?
      true
    end

    def ==(other)
      other.instance_of?(self.class)
    end

    def hash
      [self.class].hash
    end

    def eql?(other)
      self == other
    end

    def subtype_of?(other)
      self == other
    end
  end
end