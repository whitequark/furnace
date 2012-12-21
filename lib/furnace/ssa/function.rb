module Furnace::SSA
  class Function
    attr_accessor :arguments
    attr_accessor :return_type

    attr_reader   :basic_blocks
    attr_accessor :entry

    def initialize(arguments=[], return_type=nil)
      @return_type   = return_type
      self.arguments = arguments

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

    def self.inspect_as_type
      'function'
    end

    def inspect(name=nil)
      string =  "#{Furnace::SSA.inspect_type @return_type} "
      string << "function"
      string << " #{name}" if name
      string << "(#{ @arguments.map(&:inspect).join(", ") }) {\n"

      each do |block|
        string << block.inspect + "\n"
      end

      string << "}"

      string
    end

    def to_graphviz
      Furnace::Graphviz.new do |graph|
        @basic_blocks.each do |block|
          options = {}

          if @entry == block
            options.merge!({ color: 'green' })
          elsif block.returns?
            options.merge!({ color: 'red'   })
          end

          graph.node block.label, block.inspect, options

          block.successor_labels.each do |label|
            graph.edge block.label, label
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