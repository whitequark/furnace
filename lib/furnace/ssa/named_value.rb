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
    end

    def function=(function)
      if @function != function
        @function = function

        self.name = @name
      end

      function
    end

    def detach
      @function = nil
    end

    def awesome_print_as_value(p=AwesomePrinter.new)
      p.name(@name)
    end

    def inspect
      awesome_print
    end
  end
end
