module Furnace
  class SSA::Constant < SSA::Value
    attr_reader :type
    attr_reader :value

    def initialize(type, value)
      @value = value
      @type  = type.to_type

      super()
    end

    def type=(type)
      @type  = type.to_type

      SSA.instrument(self)
    end

    def value=(value)
      @value = value

      SSA.instrument(self)
    end

    def constant?
      true
    end

    def ==(other)
      if other.respond_to? :to_value
        other_value = other.to_value

        other_value.constant? &&
            other_value.type  == type &&
            other_value.value == value
      else
        false
      end
    end

    def awesome_print_as_value(p=AwesomePrinter.new)
      type.awesome_print(p)
      p.text @value.inspect
      p
    end

    def inspect
      awesome_print
    end
  end
end
