module Furnace
  class Type::Top
    class << self
      def normalize(*params)
        params
      end

      def new(*params)
        @instances[normalize(*params)]
      end

      protected

      def setup_singleton
        @instances = Hash.new do |hash, params|
          inst = allocate
          inst.send :initialize, *params
          inst.freeze

          hash[params] = inst
        end
      end

      def inherited(klass)
        klass.setup_singleton
      end
    end

    setup_singleton

    def to_type
      self
    end

    def subtype_of?(other)
      other.instance_of?(Type::Top) ||
          self == other
    end

    def supertype_of?(other)
      other.subtype_of?(self)
    end

    def variable?
      false
    end

    def replace_type_with(type, replacement)
      if self == type
        replacement.to_type
      else
        self
      end
    end

    def to_s
      'top'
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      p.type self.to_s
    end
  end
end