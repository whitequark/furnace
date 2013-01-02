module Furnace
  class SSA::NamedValue < SSA::Value
    attr_reader   :function
    attr_accessor :name

    def initialize(function, name)
      @function, @name = function, name
      @name = @function.make_name if @name.nil?
    end

    def inspect_as_value(p=SSA::PrettyPrinter.new)
      p.name name
    end
  end
end