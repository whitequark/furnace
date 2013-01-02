module Furnace
  class SSA::Function
    attr_accessor :name
    attr_reader   :arguments
    attr_accessor :return_type

    attr_accessor :entry

    def initialize(name=nil, arguments=[], return_type=SSA::Void)
      @name          = name
      self.arguments = arguments
      @return_type   = return_type

      @basic_blocks  = Set.new

      @next_name     = 0
    end

    def arguments=(arguments)
      @arguments = sanitize_arguments(arguments)
    end

    def make_name
      @next_name += 1
    end

    def each(&proc)
      @basic_blocks.each(&proc)
    end

    def include?(name)
      @basic_blocks.any? { |n| n.name == name }
    end

    def find(name)
      if block = @basic_blocks.find { |n| n.name == name }
        block
      else
        raise ArgumentError, "Cannot find basic block #{name}"
      end
    end

    def add(block)
      if include?(block.name)
        raise ArgumentError, "function #{name}: block #{block.name} already exists"
      end

      @basic_blocks.add block
    end

    alias << add

    def remove(block)
      @basic_blocks.delete block
    end

    def each_instruction(&proc)
      each do |block|
        block.each(&proc)
      end
    end

    def predecessors_for(name)
      predecessors = Set[]

      each do |block|
        if block.successor_names.include? name
          predecessors << block
        end
      end

      predecessors
    end

    def to_value
      SSA::Constant.new(SSA::Function, @name)
    end

    def self.inspect_as_type
      'function'
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      p.keyword 'function'
      p.type    @return_type
      p.text    @name, '('
      p.objects @arguments
      p.text    ') {'
      p.newline

      each do |basic_block|
        basic_block.pretty_print(p)
        p.newline
      end

      p.text    "}"
      p.newline
    end

    def to_graphviz
      Graphviz.new do |graph|
        @basic_blocks.each do |block|
          options = {}

          if @entry == block
            options.merge!({ color: 'green' })
          elsif block.returns?
            options.merge!({ color: 'red'   })
          end

          graph.node block.name, block.inspect, options

          block.successor_names.each do |name|
            graph.edge block.name, name
          end
        end
      end
    end

    protected

    def sanitize_arguments(arguments)
      arguments.each_with_index do |argument, index|
        if !argument.is_a?(SSA::Argument)
          raise ArgumentError, "function #{@name} arguments: #{argument.inspect} (at #{index}) is not an Argument"
        end
      end
    end
  end
end