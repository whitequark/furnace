module Furnace
  class SSA::Argument < SSA::NamedValue
    attr_accessor :type

    def initialize(function, type, name)
      super(function, name)
      @type = type
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      p.type type
      p.name name
    end
  end
end