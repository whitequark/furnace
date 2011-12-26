module Furnace
  module AST
    class SymbolicNode
      def initialize(name)
        @name = name.to_sym
      end

      def to_sym
        @name
      end

      def ===(name)
        @name == name.to_sym
      end

      def inspect
        @name.to_s
      end
    end

    class MethodName < SymbolicNode
      def inspect
        ".#{@name}"
      end
    end

    class LocalVariable < SymbolicNode
      def inspect
        "%#{@name}"
      end
    end

    class Constant < SymbolicNode
    end
  end
end