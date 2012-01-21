module Furnace::AST
  class Node
    attr_accessor :type, :parent, :children, :metadata

    def initialize(type, children=[], metadata={})
      @type, @children, @metadata = type.to_sym, children, metadata
      @children.each do |child|
        child.parent = self
      end
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

    def to_s
      "(#{fancy_type} ...)"
    end

    def to_sexp(indent=0)
      str = "#{"  " * indent}(#{fancy_type}"

      children.each do |child|
        if (!children[0].is_a?(Node) && child.is_a?(Node)) ||
            (children[0].is_a?(Node) && child.is_a?(Node) &&
              child.children.any? { |c| c.is_a?(Node) })
          str << "\n#{child.to_sexp(indent + 1)}"
        else
          str << " #{child.inspect}"
        end
      end

      str << ")"

      str
    end
    alias :inspect :to_sexp

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