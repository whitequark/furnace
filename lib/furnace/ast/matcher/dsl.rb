module Furnace::AST
  class MatcherDSL < BasicObject
    SpecialAny    = MatcherSpecial.new(:any)
    SpecialSkip   = MatcherSpecial.new(:skip)
    SpecialSubset = MatcherSpecial.define(:subset)

    def any
      SpecialAny
    end

    def skip
      SpecialSkip
    end

    def subset
      SpecialSubset
    end

    def capture(name)
      MatcherSpecial.new(:capture, name)
    end

    def backref(name)
      MatcherSpecial.new(:backref, name)
    end
  end
end