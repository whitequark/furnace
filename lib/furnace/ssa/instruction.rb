module Furnace::SSA
  class Instruction
    attr_reader :basic_block, :uses, :defs

    def self.instruction_name
      name.split('::').last.gsub(/([a-z]|^)([A-Z])/) do
        if $1.empty?
          $2.downcase
        else
          "#{$1}_#{$2.downcase}"
        end
      end
    end

    def initialize(basic_block, uses=[])
      @basic_block = basic_block
      self.uses = uses
    end

    def name
      self.class.instruction_name
    end

    def function
      @basic_block.function
    end

    def use_count
      0
    end

    def use_types
      @uses.map(&:type)
    end

    def def_count
      0
    end

    def def_types
      []
    end

    def uses=(new_uses)
      @uses = sanitize_values(new_uses, use_count)
      update_defs!

      @uses
    end

    def update_defs!
      @defs = []

      def_count.times.zip(def_types) do |index, type|
        if @defs[index].nil?
          @defs[index] = Value.new(function.make_name, type)
        else
          @defs[index].type = type
        end
      end

      @defs.freeze
    end

    def has_side_effects?
      false
    end

    def evaluate(context)

    end

    def inspect
      if @defs.count > 1
        defs = "{ #{@defs.map(&:inspect).join(", ")} }"
      elsif @defs.count == 1
        defs = @defs.first.inspect
      end

      if @defs.count > 0
        defs = "#{defs} = "
      end

      uses = " #{@uses.map(&:inspect).join(", ")}"

      "#{defs}#{name}#{uses}"
    end

    protected

    def typeof(value)
      if value.type.nil?
        raise "#{value} does not have a type"
      else
        value.type
      end
    end

    def sanitize_values(values, size)
      values = values.each_with_index.map do |value, index|
        if !value.is_a?(Value) && !value.is_a?(Immediate)
          raise "#{name}: #{value} (at #{index}) is not a Value or Immediate"
        end

        value
      end

      unless size.nil?
        if values.size <= size
          values += [nil] * (size - values.size)
        else
          raise "#{name}: too much values provided: #{values.size} for #{size}"
        end
      end

      values.freeze
    end
  end
end