module Furnace::AST
  class Node
    attr_reader :type, :children

    def initialize(type, children=[], properties={})
      @type, @children = type.to_sym, children.to_a.freeze

      properties.each do |name, value|
        instance_variable_set :"@#{name}", value
      end

      freeze
    end

    protected :dup

    def updated(type=nil, children=nil, properties=nil)
      new_type       = type       || @type
      new_children   = children   || @children
      new_properties = properties || {}

      if @type == new_type &&
          @children == new_children &&
          properties.nil?
        self
      else
        dup.send :initialize, new_type, new_children, new_properties
      end
    end

    def ==(other)
      if equal?(other)
        true
      elsif other.respond_to? :to_ast
        other = other.to_ast
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
      sexp = "#{"  " * indent}(#{fancy_type}"

      first_node_child = children.index do |child|
        child.is_a?(Node) || child.is_a?(Array)
      end || children.count

      children.each_with_index do |child, idx|
        if child.is_a?(Node) && idx >= first_node_child
          sexp << "\n#{child.to_sexp(indent + 1)}"
        else
          sexp << " #{child.inspect}"
        end
      end

      sexp << ")"

      sexp
    end
    alias :inspect :to_sexp

    def to_ast
      self
    end

    protected

    def fancy_type
      @type.to_s.gsub('_', '-')
    end
  end
end