module Furnace::AST
  class Node
    attr_accessor :type, :children, :metadata

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

    def dup
      node = super
      node.children = @children.dup
      node.metadata = @metadata.dup
      node
    end

    def ==(other)
      if other.respond_to? :to_astlet
        other = other.to_astlet
        other.type == self.type &&
          other.children == self.children
      else
        false
      end
    end

    def to_s
      "(#{fancy_type} ...)"
    end

    def to_sexp(indent=0)
      str = "#{"  " * indent}(#{fancy_type}"

      children.each do |child|
        if (!children[0].is_a?(Node) && child.is_a?(Node)) ||
            (children[0].is_a?(Node) && child.is_a?(Node) &&
              child.children.any? { |c| c.is_a?(Node) || c.is_a?(Array) }) ||
            (child.is_a?(Node) && child.metadata[:label])
          str << "\n#{child.to_sexp(indent + 1)}"
        else
          str << " #{child.inspect}"
        end
      end

      str << ")"

      str
    end
    alias :inspect :to_sexp

    def to_astlet
      self
    end

    protected

    def fancy_type
      dasherized = @type.to_s.gsub('_', '-')

      if (@metadata.keys - [:label, :origin]).any?
        metainfo = @metadata.dup
        metainfo.delete :label
        metainfo.delete :origin
        metainfo = "#{metainfo.inspect}:"
      end

      if @metadata[:label]
        "#{@metadata[:label]}:#{metainfo}#{dasherized}"
      else
        "#{metainfo}#{dasherized}"
      end
    end
  end
end