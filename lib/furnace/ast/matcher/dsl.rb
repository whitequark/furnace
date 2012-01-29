module Furnace::AST
  class MatcherDSL
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

    def map(name)
      ->(hash) { MatcherSpecial.new(:map, [name, hash]) }
    end

    def capture(name)
      MatcherSpecial.new(:capture, name)
    end

    def backref(name)
      MatcherSpecial.new(:backref, name)
    end
  end
end