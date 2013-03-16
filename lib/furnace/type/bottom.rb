module Furnace
  class Type::Bottom < Type::Top
    def subtype_of?(other)
      other.is_a?(Type::Top)
    end

    def to_s
      'bottom'
    end
  end
end
