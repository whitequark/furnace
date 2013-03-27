module Furnace
  class SSA::User < SSA::NamedValue
    attr_reader :operands

    def initialize(operands=[], name=nil)
      super(name)

      self.operands = operands
    end

    def initialize_copy(original)
      @operands = nil

      super
    end

    def each_operand(&block)
      @operands.each &block if @operands
    end

    def operands=(operands)
      update_use_lists do
        @operands = operands.map(&:to_value)
      end
    end

    def drop_references
      update_use_lists do
        @operands = nil
      end
    end

    def translate_operands(map)
      @operands.map do |operand|
        map[operand]
      end
    end

    def replace_uses_of(value, new_value)
      if replace_uses_of_operands(value, new_value)
        value.remove_use(self)
        new_value.add_use(self)
      else
        raise ArgumentError, "#{value.inspect} is not used in #{self.inspect}"
      end

      self
    end

    protected

    def update_use_lists
      each_operand do |operand|
        operand.remove_use(self)
      end

      value = yield

      each_operand do |operand|
        operand.add_use(self)
      end

      SSA.instrument(self)

      value
    end

    def replace_uses_of_operands(value, new_value)
      found = false

      @operands.each_with_index do |operand, index|
        if operand == value
          found = true
          @operands[index] = new_value
        end
      end

      SSA.instrument(self)

      found
    end
  end
end
