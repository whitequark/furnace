module Furnace::AST
  class MatcherSpecial
    attr_reader :type, :params

    def initialize(type, params=nil)
      @type, @params = type, params
    end

    def self.define(type)
      lambda { |*args| new(type, args) }
    end
  end
end