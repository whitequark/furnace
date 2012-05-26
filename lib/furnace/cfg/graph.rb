module Furnace::CFG
  class Graph
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

    def eliminate_unreachable!
      queue     = [entry]
      reachable = Set[]

      while queue.any?
        node = queue.shift
        reachable.add node

        node.targets.each do |target|
          unless reachable.include? target
            queue.push target
          end
        end

        if node.exception
          unless reachable.include? node.exception
            queue.push node.exception
          end
        end
      end

      @nodes.each do |node|
        @nodes.delete node unless reachable.include? node
      end

      flush
    end

    def merge_redundant!
      worklist = @nodes.dup
      while worklist.any?
        node = worklist.first
        worklist.delete node

        target = node.targets[0]
        next if target == @exit

        # Skip explicitly non-redundant nodes
        if node.cti && node.cti.metadata[:keep]
          next
        end

        if node.targets.count == 1 &&
            target.sources.count == 1 &&
            node.exception == target.exception

          node.insns.delete node.cti
          @nodes.delete node
          @nodes.delete target

          new_node = Node.new(self,
              node.label,
              node.insns + target.insns,
              target.cti,
              target.target_labels)
          @nodes.add new_node
          worklist.add new_node

          if @entry == node
            @entry = new_node
          end

          flush
        elsif node.targets.count == 1 &&
            node.insns.empty?
          target = node.targets.first

          node.sources.each do |source|
            index = source.targets.index(node)
            source.target_labels[index] = target.label
          end

          @nodes.delete node

          flush
        end
      end
    end

    # Shamelessly stolen from
    # http://www.cs.colostate.edu/~mstrout/CS553/slides/lecture04.pdf
    def dominators
      unless @dominators
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

            #   Key Idea
            # If a node dominates all
            # predecessors of node n, then it
            # also dominates node n.
            pred = node.sources.map do |source|
              dom[source]
            end.reduce(:&)

            # An exception handler header node has no regular sources.
            pred = [] if pred.nil?

            current = Set[node].merge(pred)
            if current != dom[node]
              dom[node] = current
              change = true
            end
          end
        end

        @dominators = dom
      end

      @dominators
    end

    # See also {#dominators} for references.
    def identify_loops
      loops = Hash.new { |h,k| h[k] = Set.new }

      dom = dominators
      @nodes.each do |node|
        node.targets.each do |target|
          #   Back edges
          # A back edge of a natural loop is one whose
          # target dominates its source.
          if dom[node].include? target
            loops[target].add node
          end
        end
      end

      # At this point, +loops+ contains a list of all nodes
      # which have a back edge to the loop header. Expand
      # it to the list of all nodes in the loop.
      loops.each do |header, nodes|
        #   Natural loop
        # The natural loop of a back edge (m→n), where
        # n dominates m, is the set of nodes x such that n
        # dominates x and there is a path from x to m not
        # containing n.
        pre_header = dom[header]
        all_nodes  = Set[header]

        nodes.each do |node|
          all_nodes.merge(dom[node] - pre_header)
        end

        nodes.replace all_nodes
      end

      loops.default = nil
      loops
    end

    def sources_for(node)
      unless @source_map
        @source_map = Hash.new { |h, k| h[k] = [] }

        @nodes.each do |node|
          node.targets.each do |target|
            @source_map[target] << node
          end
        end

        @source_map.each do |node, sources|
          sources.freeze
        end
      end

      @source_map[node]
    end

    def flush
      @source_map = nil
      @label_map.clear
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

          if node.exception_label
            graph.edge node.label, node.exception_label, "Exc", color: 'orange'
          end
        end
      end
    end
  end
end