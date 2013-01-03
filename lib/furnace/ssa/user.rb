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

    def valid?(*args)
      verify!(*args)
      true
    rescue TypeError
      false
    end

    def verify!
      # do nothing
    end
  end
end