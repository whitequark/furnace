module Furnace::AST
  class Matcher
    SpecialAny    = MatcherSpecial.new(:any)
    SpecialSubset = MatcherSpecial.define(:subset)

    def initialize(&block)
      @pattern = self.class.class_exec(&block)
    end

    def match(object)
      genmatch(object.to_astlet, @pattern)
    end

    def find_one(collection)
      collection.find do |elem|
        result = match elem
        yield elem, result if block_given? && result
        result
      end
    end

    def find_all(collection)
      collection.select do |elem|
        result = match elem
        yield elem, result if block_given? && result
        result
      end
    end

    class << self
      def any
        SpecialAny
      end

      def subset
        SpecialSubset
      end

      def capture(name)
        MatcherSpecial.new(:capture, name)
      end
    end

    protected

    def submatch(array, pattern)
      matches = true

      pattern.each_with_index do |subpattern, index|
        if array[index].nil?
          return false
        end

        case subpattern
        when SpecialAny
          # it matches
        when MatcherSpecial
          if subpattern.type == :subset
            all_submatches = true

            subpattern.params.each do |pattern_case|
              submatches = false
              array[index..-1].each do |subset_elem|
                submatches ||= genmatch(subset_elem, pattern_case)
                break if submatches
              end

              all_submatches &&= submatches
              break unless all_submatches
            end

            matches &&= all_submatches
          end
        when Array
          matches &&= genmatch(array[index], subpattern)
        else
          matches &&= array[index] == subpattern
        end

        break unless matches
      end

      matches
    end

    def genmatch(astlet, pattern)
#       if astlet.respond_to? :to_sexp
#         puts "match #{astlet.to_sexp} of #{pattern}"
#       else
#         puts "match #{astlet} of #{pattern}"
#       end

      if pattern.first.is_a?(Symbol)
        # Match an astlet
        type, *rest = pattern

        if astlet.is_a? Node
          if astlet.type == type
            submatch(astlet.children, rest)
          else
            false
          end
        else
          false
        end
      else
        # Match an array
        if astlet.is_a? Array
          submatch(astlet, pattern)
        else
          false
        end
      end
    end
  end
end