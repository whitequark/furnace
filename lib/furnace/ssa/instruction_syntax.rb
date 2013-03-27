module Furnace
  class SSA::InstructionSyntax
    def initialize(klass)
      @klass    = klass
      @operands = []
      @splat    = nil
    end

    def evaluate
      yield self

      codegen
    end

    def operand(name)
      check_for_splat

      @operands << name.to_sym
    end

    def splat(name)
      check_for_splat

      @splat = name.to_sym
    end

    protected

    def check_for_splat
      if @splat
        raise ArgumentError, "There should be at most one splat operand in tail position"
      end
    end

    def codegen
      operands, splat = @operands, @splat

      @klass.class_eval do
        operands.each_with_index do |operand, index|
          define_method(operand) do
            @operands[index]
          end

          define_method(:"#{operand}=") do |value|
            value = value.to_value

            return if @operands[index] == value

            @operands[index].remove_use self if @operands[index]
            @operands[index] = value
            value.add_use self if value

            SSA.instrument(self)

            value
          end
        end

        if splat
          define_method splat do
            @operands[operands.size..-1]
          end

          define_method(:"#{splat}=") do |values|
            values = values.map(&:to_value)

            update_use_lists do
              @operands[operands.size, @operands.size - operands.size] = values
            end

            values
          end
        end

        define_method(:operands=) do |values|
          if splat && values.size < operands.size
            raise ArgumentError, "Not enough operands provided: #{values.size} for #{operands.size}"
          elsif !splat && values.size != operands.size
            raise ArgumentError, "Incorrect number of operands provided: #{values.size} for #{operands.size}"
          end

          values = values.map(&:to_value)

          update_use_lists do
            @operands = values
          end

          values
        end
      end
    end
  end
end
