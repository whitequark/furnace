module Furnace
  module AST
    class Node
      attr_accessor :type, :parent, :children, :metadata

      def initialize(type, children=[], metadata={})
        @type, @children, @metadata = type.to_sym, children, metadata
      end

      def update(type, children=nil, metadata={})
        @type     = type
        @children = children || @children

        # If something non-nil is passed, including default value, then merge.
        # Else, clear metadata store.
        if metadata
          @metadata.merge!(metadata)
        else
          @metadata = {}
        end

        self
      end

      def index
        parent.children.find_index(self)
      end

      def next
        parent.children[index + 1]
      end

      def prev
        parent.children[index - 1]
      end

      def inspect
        "(#{fancy_type} ...)"
      end

      def to_sexp(indent=0)
        str = "#{"  " * indent}(#{fancy_type}"

        children.each do |child|
          if child.is_a? Node
            str << "\n#{child.to_sexp(indent + 1)}"
          else
            str << " #{child.inspect}"
          end
        end

        str << ")"

        str
      end

      protected

      def fancy_type
        dasherized = @type.to_s.gsub('_', '-')
        if @metadata[:label]
          "#{@metadata[:label]}:#{dasherized}"
        else
          dasherized
        end
      end
    end
  end
end