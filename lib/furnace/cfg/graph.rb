module Furnace::CFG
  class Graph
    attr_reader   :nodes
    attr_accessor :entry, :exit

    def initialize
      @nodes = Set.new
    end

    def find_node(label)
      if node = @nodes.find { |n| n.label == label }
        node
      else
        raise "Cannot find CFG node #{label}"
      end
    end

    def eliminate_unreachable!
      unreachable = Set.new

      worklist = @nodes.dup
      while worklist.any?
        node = worklist.first
        worklist.delete node

        next if node == @entry

        if node.sources.count == 0
          unreachable.add node
        end
      end

      @nodes = @nodes - unreachable
      flush
    end

    def merge_redundant!
      worklist = @nodes.dup
      while worklist.any?
        node = worklist.first
        worklist.delete node

        target = node.targets[0]
        next if target == @exit

        if node.targets.count == 1 &&
            target.sources.count == 1
          node.insns.delete node.cfi
          @nodes.delete node
          @nodes.delete target

          new_node = Node.new(self,
              node.label,
              node.insns + target.insns,
              target.cfi,
              target.target_labels)
          @nodes.add new_node
          worklist.add new_node

          if @entry == node
            @entry = new_node
          end

          flush
        end
      end
    end

    # Shamelessly stolen from
    # http://www.cs.colostate.edu/~mstrout/CS553/slides/lecture04.pdf
    def dominators
      # values of β will give rise to dom!
      dom = { @entry => Set[@entry] }

      @nodes.each do |node|
        next if node == @entry
        dom[node] = @nodes.dup
      end

      change = true
      while change
        change = false
        @nodes.each do |node|
          next if node == @entry

          pred = node.sources.map do |source|
            dom[source]
          end.reduce(:&)

          current = Set[node].merge(pred)
          if current != dom[node]
            dom[node] = current
            change = true
          end
        end
      end

      dom
    end

    def source_map
      unless @source_map
        @source_map = Hash.new { |h, k| h[k] = [] }

        @nodes.each do |node|
          node.targets.each do |target|
            @source_map[target] << node
          end
        end
      end

      @source_map
    end

    def flush
      @source_map = nil
    end

    def to_graphviz
      Furnace::Graphviz.new do |graph|
        @nodes.each do |node|
          if node.label == nil
            contents = "<exit>"
          else
            contents = "<#{node.label.inspect}>\n#{node.insns.map(&:inspect).join("\n")}"
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
        end
      end
    end
  end
end