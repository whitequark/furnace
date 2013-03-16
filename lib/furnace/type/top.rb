module Furnace
  class Type::Top
    class << self
      def new(*params)
        @instances[params]
      end

      protected

      def setup_singleton
        @instances = Hash.new do |hash, params|
          inst = allocate
          inst.send :initialize, *params

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

    def covariant?(other)
      false
    end

    def contravariant?(other)
      false
    end

    def ==(other)
      eql? other
    end

    def eql?(other)
      other.instance_of?(self.class)
    end

    def hash
      [self.class].hash
    end
  end
end
