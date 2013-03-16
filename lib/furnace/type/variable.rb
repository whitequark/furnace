module Furnace
  class Type::Variable
    def to_type
      self
    end

    def subtype_of?(other)
      other.instance_of?(Type::Top) ||
          self == other
    end

    def supertype_of?(other)
      other.subtype_of?(self)
    end
  end

  class Type::Variable::Annotator
    def initialize
      @last_annotation = "a"

      @annotations = Hash.new do |hash, var|
        unless var.is_a? Type::Variable
          raise ArgumentError, "#{self.class} cannot annotate #{var.class}"
        end

        annotation       = @last_annotation
        @last_annotation = @last_annotation.succ

        hash[var] = annotation
      end
    end

    def annotate(var)
      @annotations[var]
    end
  end
end
