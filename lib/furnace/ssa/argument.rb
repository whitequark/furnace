module Furnace
  class SSA::Argument < SSA::NamedValue
    attr_reader :type

    def initialize(type, name)
      @type = type.to_type

      super(name)
    end

    def type=(type)
      @type = type.to_type

      SSA.instrument(self)
    end

    def replace_type_with(type, replacement)
      self.type = self.type.
          replace_type_with(type, replacement)
    end

    def awesome_print(p=AwesomePrinter.new)
      p.nest(@type).
        name(name)
    end
  end
end
