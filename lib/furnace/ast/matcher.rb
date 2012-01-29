module Furnace::AST
  class MatcherError < StandardError; end

  class Matcher
    def initialize(&block)
      @pattern = MatcherDSL.new.instance_exec(&block)
    end

    def match(object, captures={})
      if genmatch(object.to_astlet, @pattern, captures)
        captures
      else
        nil
      end
    end

    def find_one(collection, initial_captures={})
      collection.find do |elem|
        result = match elem, initial_captures.dup

        if block_given? && result
          yield elem, result
        else
          result
        end
      end
    end

    def find_one!(collection, initial_captures={})
      found = nil

      collection.each do |elem|
        result = match elem, initial_captures.dup

        if result
          raise MatcherError, "already matched" if found

          found = elem
          yield elem, result if block_given?
        end
      end

      raise MatcherError, "no match found" unless found

      found
    end

    def find_all(collection, initial_captures={})
      collection.select do |elem|
        result = match elem, initial_captures.dup
        yield elem, result if block_given? && result
        result
      end
    end

    protected

    def submatch(array, pattern, captures)
      matches = true
      nested_captures = captures.dup
      index   = 0

      pattern.each_with_index do |nested_pattern|
        return nil if index > array.length

        case nested_pattern
        when Array
          matches &&= genmatch(array[index], nested_pattern, nested_captures)
          index += 1
        when MatcherDSL::SpecialAny
          # it matches
          index += 1
        when MatcherDSL::SpecialSkip
          # it matches all remaining elements
          index = array.length
        when MatcherSpecial.kind(:capture)
          # it matches and captures
          nested_captures[nested_pattern.param] = array[index]
          index += 1
        when MatcherSpecial.kind(:backref)
          matches &&= (nested_captures[nested_pattern.param] == array[index])
          index += 1
        when MatcherSpecial.kind(:maybe)
          if advance = submatch(array[index..-1], nested_pattern.param, nested_captures)
            index += advance
          end
        when MatcherSpecial.kind(:each)
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

          index += 1
          matches &&= all_submatches
        when MatcherSpecial.kind(:either)
          sub_found = false

          nested_pattern.param.each do |subset_pattern|
            if genmatch(array[index], subset_pattern, nested_captures)
              sub_found = true
              break
            end
          end

          index += 1
          matches &&= sub_found
        when MatcherSpecial.kind(:map)
          captures_key, patterns = nested_pattern.param
          nested_captures[captures_key] = []

          while index < array.length
            sub_found = false

            patterns.each do |subset_key, subset_pattern|
              subset_captures = captures.dup

              if matched = submatch(array[index..-1], subset_pattern, subset_captures)
                nested_captures[captures_key].push [subset_key, subset_captures]

                sub_found = true
                index += matched

                break
              end
            end

            matches &&= sub_found
            break unless matches
          end
        else
          matches &&= (nested_pattern === array[index])
          index += 1
        end

        break unless matches
      end

      captures.replace(nested_captures) if matches

      index if matches
    end

    def genmatch(astlet, pattern, captures)
      if $DEBUG
        if astlet.respond_to? :to_sexp
          puts "match #{astlet.to_sexp} of #{pattern}"
        else
          puts "match #{astlet} of #{pattern}"
        end
      end

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