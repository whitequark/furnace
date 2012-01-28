module Furnace::AST
  class Matcher
    def initialize(&block)
      @pattern = self.class.class_exec(&block)
    end

    def match(object)
      captures = {}

      if genmatch(object.to_astlet, @pattern, captures)
        captures
      else
        nil
      end
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

    SpecialAny    = MatcherSpecial.new(:any)
    SpecialSkip   = MatcherSpecial.new(:skip)
    SpecialSubset = MatcherSpecial.define(:subset)

    class << self
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

    protected

    def submatch(array, pattern, captures)
      matches = true
      nested_captures = captures.dup

      pattern.each_with_index do |nested_pattern, index|
        return false if index > array.length

        case nested_pattern
        when Array
          matches &&= genmatch(array[index], nested_pattern, nested_captures)
        when SpecialAny
          # it matches
        when SpecialSkip
          # it matches all remaining elements
          break
        when MatcherSpecial.kind(:capture)
          # it matches and captures
          nested_captures[nested_pattern.param] = array[index]
        when MatcherSpecial.kind(:backref)
          matches &&= (nested_captures[nested_pattern.param] == array[index])
        when MatcherSpecial.kind(:subset)
          all_submatches = true

          workset = Set.new array[index..-1]

          nested_pattern.param.each do |subset_pattern|
            sub_matches  = false

            workset.each do |subset_elem|
              sub_matches ||= genmatch(subset_elem, subset_pattern, nested_captures)

              if sub_matches
                workset.delete subset_elem
                break
              end
            end

            all_submatches &&= sub_matches
            break unless all_submatches
          end

          matches &&= all_submatches
        else
          matches &&= (array[index] == nested_pattern)
        end

        break unless matches
      end

      captures.replace(nested_captures) if matches

      matches
    end

    def genmatch(astlet, pattern, captures)
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
            submatch(astlet.children, rest, captures)
          else
            false
          end
        else
          false
        end
      else
        # Match an array
        if astlet.is_a? Array
          submatch(astlet, pattern, captures)
        else
          false
        end
      end
    end
  end
end