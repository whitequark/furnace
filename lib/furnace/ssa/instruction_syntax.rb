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
          attr_reader operand

          define_method(:"#{operand}=") do |value|
            value = value.to_value

            instance_variable_set :"@#{operand}", value

            @operands[index].remove_use self if @operands[index]
            @operands[index] = value
            value.add_use self if value

            value
          end
        end

        if splat
          attr_reader splat

          define_method(:"#{splat}=") do |value|
            value = value.to_a

            instance_variable_set :"@#{splat}", value

            update_use_lists do
              @operands.slice! operands.size, -1
              @operands.insert operands.size, *value
            end

            value
          end
        end

        define_method(:operands=) do |values|
          if splat && values.size < operands.size
            raise ArgumentError, "Not enough operands provided: #{values.size} for #{operands.size}"
          elsif !splat && values.size != operands.size
            raise ArgumentError, "Incorrect number of operands provided: #{values.size} for #{operands.size}"
          end

          @operands = []

          operands.keys.each_with_index do |operand, index|
            send :"#{operand}=", values[index]
          end

          if splat
            send :"#{splat}=", values[operands.size..-1]
          end

          verify!

          values
        end

        define_method(:verify!) do |ignore_nil_types=true|
          operands.each_with_index do |(operand, type), index|
            next if type.nil?

            value = send operand
            next if ignore_nil_types && value.type.nil?

            if value.type != type
              raise TypeError, "Wrong type for operand ##{index + 1} `#{operand}': #{SSA.inspect_type type} is expected, #{SSA.inspect_type value.type} is present"
            end
          end

          nil
        end
      end
    end
  end
end