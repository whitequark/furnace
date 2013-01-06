module Furnace
  class SSA::Argument < SSA::NamedValue
    attr_accessor :type

    def initialize(function, type, name)
      super(function, name)
      @type = type
    end

    def has_side_effects?
      true
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      p.type type
      p.name name
    end
  end
end