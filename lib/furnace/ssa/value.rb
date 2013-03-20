module Furnace
  class SSA::Value
    def initialize
      @uses = Set.new
    end

    def initialize_copy(original)
      @uses = Set.new
    end

    def type
      Type::Bottom.new
    end

    def constant?
      false
    end

    def add_use(use)
      @uses.add use
    end

    def remove_use(use)
      @uses.delete use
    end

    def each_use(&block)
      @uses.each(&block)
    end

    def use_count
      @uses.count
    end

    def used?
      @uses.any?
    end

    def replace_all_uses_with(value)
      each_use do |user|
        user.replace_uses_of self, value
      end
    end

    def to_value
      self
    end

    def ==(other)
      other.respond_to?(:to_value) &&
          equal?(other.to_value)
    end

    def awesome_print(p=AwesomePrinter.new)
      inspect_as_value(p)
    end

    def inspect_as_value(p=AwesomePrinter.new)
      p.text inspect
    end
  end
end
