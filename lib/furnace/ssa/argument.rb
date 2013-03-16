module Furnace
  class SSA::Argument < SSA::NamedValue
    attr_reader :type

    def initialize(function, type, name)
      super(function, name)
      self.type = type
    end

    def type=(type)
      @type = type.to_type
    end

    def replace_type_with(type, replacement)
      self.type = self.type.replace_type_with(type, replacement)
    end

    def has_side_effects?
      true
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      @type.pretty_print(p)
      p.name name
    end
  end
end
