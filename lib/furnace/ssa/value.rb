module Furnace
  class SSA::Value
    def type
      SSA::Void
    end

    def constant?
      false
    end

    def to_value
      self
    end

    def ==(other)
      other.respond_to?(:to_value) &&
          equal?(other.to_value)
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      inspect_as_value(p)
    end

    def inspect_as_value(p=SSA::PrettyPrinter.new)
      p.text inspect
    end
  end
end