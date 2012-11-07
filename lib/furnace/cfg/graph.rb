module Furnace::CFG
  class Graph
    include Algorithms

    attr_reader   :nodes
    attr_accessor :entry, :exit

    def initialize
      @nodes = Set.new

      @source_map = nil
      @label_map  = {}
    end

    def find_node(label)
      if node = @label_map[label]
        node
      elsif node = @nodes.find { |n| n.label == label }
        @label_map[label] = node
        node
      else
        raise "Cannot find CFG node #{label}"
      end
    end

    def sources_for(node, find_exceptions=false)
      unless @source_map
        @source_map = Hash.new { |h, k| h[k] = [] }
        @exception_source_map = Hash.new { |h, k| h[k] = [] }

        @nodes.each do |node|
          node.targets.each do |target|
            @source_map[target] << node
          end

          @exception_source_map[node.exception] << node
        end

        @source_map.each do |node, sources|
          sources.freeze
        end

        @exception_source_map.each do |node, sources|
          sources.freeze
        end
      end

      if find_exceptions
        @exception_source_map[node]
      else
        @source_map[node]
      end
    end

    def flush
      @source_map = nil
      @label_map.clear

      super if defined?(super)
    end

    def to_graphviz
      Furnace::Graphviz.new do |graph|
        @nodes.each do |node|
          if node.label == nil
            contents = "<exit>"
          else
            contents = "<#{node.label.inspect}>"
          end

          if node.metadata.any?
            contents << "\n#{node.metadata.inspect}"
          end

          if node.insns.any?
            contents << "\n#{node.insns.map(&:inspect).join("\n")}"
          end

          options = {}
          if @entry == node
            options.merge! color: 'green'
          elsif @exit == node
            options.merge! color: 'red'
          end

          graph.node node.label, contents, options

          node.target_labels.each_with_index do |label, idx|
            graph.edge node.label, label, "#{idx}"
          end

          if node.exception_label
            graph.edge node.label, node.exception_label, "", color: 'orange'
          end
        end
      end
    end
  end
end