module Furnace::SSA
  class Function
    attr_reader   :arguments

    attr_reader   :basic_blocks
    attr_accessor :entry

    def initialize
      @basic_blocks = Set.new

      @last_label = 0
      @last_name  = 0
    end

    def arguments=(values)
      @arguments = sanitize_values(values)
    end

    def make_label
      @last_label += 1
    end

    def make_name
      @last_name += 1
    end

    def add(block)
      @basic_blocks.add block
    end

    def remove(block)
      @basic_blocks.delete block
    end

    def each(&proc)
      @basic_blocks.each(&proc)
    end

    def find(label)
      if block = @basic_blocks.find { |n| n.label == label }
        block
      else
        raise "Cannot find CFG node #{label}"
      end
    end

    def predecessors_for(block)
      predecessors = Set[]

      each do |block|
        if block.successor_labels.include? block.label
          predecessors << block
        end
      end

      predecessors
    end

    def inspect(name=nil)
      name_string = " #{name}" if name
      string = "function#{name_string}(#{ @args.map(&:inspect).join(", ") }) {\n"

      each do |block|
        string << block.inspect + "\n"
      end

      string << "}"

      string
    end

    def to_graphviz
      Furnace::Graphviz.new do |graph|
        @nodes.each do |node|
          if @entry == node
            options = { color: 'green' }
          elsif node.returns?
            options = { color: 'red'   }
          end

          graph.node node.label, node.inspect, options

          node.target_labels.each_with_index do |label, idx|
            graph.edge node.label, label
          end
        end
      end
    end

    protected

    def sanitize_values(values)
      values = values.each_with_index.map do |value, index|
        if !value.is_a?(Value)
          raise "#{name}: #{value} (at #{index}) is not a Value"
        end

        value
      end
    end
  end
end