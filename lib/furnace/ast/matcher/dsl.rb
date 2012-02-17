module Furnace::AST
  class MatcherDSL
    SpecialAny         = MatcherSpecial.new(:any)
    SpecialSkip        = MatcherSpecial.new(:skip)
    SpecialEach        = MatcherSpecial.define(:each)
    SpecialEither      = MatcherSpecial.define(:either)
    SpecialEitherMulti = MatcherSpecial.define(:either_multi)
    SpecialMaybe       = MatcherSpecial.define(:maybe)

    def any
      SpecialAny
    end

    def skip
      SpecialSkip
    end

    def each
      SpecialEach
    end

    def either
      SpecialEither
    end

    def either_multi
      SpecialEitherMulti
    end

    def maybe
      SpecialMaybe
    end

    def map(name)
      ->(hash) { MatcherSpecial.new(:map, [name, hash]) }
    end

    def capture(name)
      MatcherSpecial.new(:capture, name)
    end

    def capture_rest(name)
      MatcherSpecial.new(:capture_rest, name)
    end

    def backref(name)
      MatcherSpecial.new(:backref, name)
    end
  end
end