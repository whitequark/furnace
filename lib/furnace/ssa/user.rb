module Furnace
  class SSA::User < SSA::NamedValue
    attr_reader :operands

    def initialize(function, operands=[], name=nil)
      super(function, name)

      self.operands = operands
    end

    def each_operand(&block)
      @operands.each &block if @operands
    end

    def operands=(operands)
      update_use_lists do
        @operands = operands.map(&:to_value)
      end
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

    protected

    def update_use_lists
      each_operand do |op|
        op.remove_use(self)
      end

      value = yield

      each_operand do |op|
        op.add_use(self)
      end

      value
    end
  end
end