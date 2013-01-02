module Furnace
  class SSA::User < SSA::NamedValue
    attr_reader :operands

    def initialize(function, operands=[], name=nil)
      super(function, name)
      self.operands = operands
    end

    def operands=(operands)
      @operands = operands.map(&:to_value)
    end
  end
end