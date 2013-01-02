module Furnace
  class SSA::User < SSA::NamedValue
    attr_accessor :operands

    def initialize(function, operands=[], name=nil)
      super(function, name)
      self.operands = operands
    end
  end
end