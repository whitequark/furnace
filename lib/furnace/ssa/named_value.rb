module Furnace
  class SSA::NamedValue < SSA::Value
    attr_reader :function
    attr_reader :name

    def initialize(name=nil)
      super()

      @function = nil
      @name     = name
    end

    def name=(name)
      if @function
        @name = @function.make_name(name)
      else
        @name = name
      end

      SSA.instrument(self)
    end

    def function=(function)
      if @function != function
        @name     = function.make_name(@name)
        @function = function
      end

      SSA.instrument(self)
    end

    def detach
      @function = nil

      SSA.instrument(self)
    end

    def awesome_print_as_value(p=AwesomePrinter.new)
      p.name(@name)
    end

    def inspect
      awesome_print
    end
  end
end
