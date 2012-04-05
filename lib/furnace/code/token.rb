module Furnace
  module Code
    class Token
      attr_reader :origin

      def initialize(origin, options={})
        @origin, @options = origin, options
        @waiters = []
      end

      def self.type
        @type ||= name.sub(/^.*::/, '').to_sym
      end

      def type
        self.class.type
      end

      def subscribe(proc)
        @waiters << proc
      end

      def unsubscribe(proc)
        @waiters.delete proc
      end

      def to_text
        raise "Reimplement Token#to_text in a subclass"
      end

      def to_structure(options={})
        structurize nil, options
      end

      protected

      def indent(code, options)
        code.to_s.gsub(/^/, (options[:indent_with] || '  ') * (options[:level] || 1))
      end

      def structurize(comment, options)
        options = { level: 0 }.merge(options)

        structure = indent(type, options)

        if comment
          structure = structure.ljust(options[:describe_at] || 50)

          if comment =~ /^\s+$/
            structure += "   <whitespace>"
          else
            structure += " ; #{comment.gsub(%r{\/\*.*?\*\/}, '').
                  gsub(/[ \t]+/, ' ').gsub("\n", '')}"
          end
        end

        structure += "\n"

        if @children
          structure += @children.map do |child|
            child.to_structure(options.merge(:level => options[:level] + 1))
          end.join
        end

        structure
      end
    end
  end
end