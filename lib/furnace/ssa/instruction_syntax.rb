module Furnace
  class SSA::InstructionSyntax
    def initialize(klass)
      @klass    = klass
      @operands = {}
      @splat    = nil
    end

    def evaluate
      yield self

      codegen
    end

    def operand(name, type=nil)
      check_for_splat

      type = type.to_type unless type.nil?
      @operands[name.to_sym] = type
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
        operands.each_with_index do |(operand, type), index|
          define_method(operand) do
            @operands[index]
          end

          define_method(:"#{operand}=") do |value|
            value = value.to_value

            @operands[index].remove_use self if @operands[index]
            @operands[index] = value
            value.add_use self if value

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

          verify!

          values
        end

        define_method(:verify!) do |ignore_nil_types=true|
          return if @operands.nil?

          operands.each_with_index do |(operand, type), index|
            next if type.nil?

            value = send operand
            next if ignore_nil_types && value.type.nil?

            if value.type.nil? || !value.type.subtype_of?(type)
              raise TypeError, "Wrong type for operand ##{index + 1} `#{operand}': #{SSA.inspect_type type} is expected, #{SSA.inspect_type value.type} is present"
            end
          end

          nil
        end
      end
    end
  end
end