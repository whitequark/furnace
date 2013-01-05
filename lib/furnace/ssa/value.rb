module Furnace
  class SSA::Value
    def initialize
      @uses = []
    end

    def type
      SSA::Void
    end

    def constant?
      false
    end

    def to_value
      self
    end

    def add_use(use)
      @uses.push use
    end

    def remove_use(use)
      @uses.delete use
    end

    def each_use(&block)
      @uses.each(&block)
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