module Furnace
  class SSA::Argument < SSA::NamedValue
    attr_reader :type

    def initialize(type, name)
      super(name)

      self.type = type
    end

    def type=(type)
      @type = type.to_type

      instrument { |i| i.set_arguments @function.arguments }
    end

    def replace_type_with(type, replacement)
      self.type = self.type.
          replace_type_with(type, replacement)
    end

    def awesome_print(p=AwesomePrinter.new)
      p.nest(@type).
        name(name)
    end

    def instrument(&block)
      @function.instrument(&block) if @function
    end
  end
end
