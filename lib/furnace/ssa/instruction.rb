module Furnace::SSA
  class Instruction
    attr_reader :basic_block, :uses, :defs

    def self.instruction_name
      name.gsub(/([a-z]|^)([A-Z])/) do
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
    end

    def update_defs!
      def_count.times.zip(def_types) do |index, type|
        if @defs[index].nil?
          Value.new(@function.make_name, type)
        else
          @defs[index].type = type
        end
      end
    end

    def has_side_effects?
      false
    end

    def evaluate(context)

    end

    def inspect
      defs = "{ #{@defs.map(&:inspect).join(", ")} }"
      uses = "#{@uses.map(&:inspect).join(", ")}"
      "#{defs.ljust(20)} = #{name} #{uses}"
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
        if values <= size
          values.resize size
        else
          raise "#{name}: too much values provided: #{values.size} for #{size}"
        end
      end

      values
    end
  end
end