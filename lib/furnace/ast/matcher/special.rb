module Furnace::AST
  class MatcherSpecial
    attr_reader :type, :param

    def initialize(type, param=nil)
      @type, @param = type, param
    end

    class << self
      def define(type)
        lambda { |*args| new(type, args) }
      end

      def kind(type)
        @kind_lambdas       ||= {}
        @kind_lambdas[type] ||= lambda { |m| m.is_a?(MatcherSpecial) && m.type == type }
      end
    end
  end
end