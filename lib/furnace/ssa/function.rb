module Furnace
  class SSA::Function
    attr_reader   :original_name
    attr_accessor :name
    attr_reader   :arguments
    attr_accessor :return_type

    attr_accessor :entry

    def initialize(name=nil, arguments=[], return_type=SSA.void)
      @original_name = name
      @name          = name
      self.arguments = arguments
      @return_type   = return_type

      @basic_blocks  = Set.new

      @name_prefixes = [nil].to_set
      @next_name     = 0
    end

    def initialize_copy(original)
      @name = @original_name

      value_map = Hash.new do |value_map, value|
        new_value = value.dup
        value_map[value] = new_value

        unless new_value.constant?
          # This is an instruction.
          # Arguments are processed explicitly.
          new_value.function = self
          new_value.operands = value.translate_operands(value_map)
        end

        new_value
      end

      @arguments = @arguments.map do |arg|
        new_arg = arg.dup
        new_arg.function = self
        value_map[arg] = new_arg

        new_arg
      end

      @basic_blocks = @basic_blocks.map do |bb|
        new_bb = bb.dup
        new_bb.function = self

        value_map[bb] = new_bb

        new_bb
      end

      @entry = value_map[@entry]

      original.each do |bb|
        new_bb = value_map[bb]

        bb.each do |insn|
          new_insn = value_map[insn]
          new_insn.basic_block = new_bb
          new_bb.append new_insn
        end
      end
    end

    def arguments=(arguments)
      @arguments = sanitize_arguments(arguments)
    end

    def make_name(prefix=nil)
      if @name_prefixes.include? prefix
        "#{prefix}#{@next_name += 1}"
      else
        @name_prefixes.add prefix
        prefix.to_s
      end
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
      @basic_blocks.add block
    end

    alias << add

    def remove(block)
      @basic_blocks.delete block
    end

    def each_instruction(type=nil, &proc)
      return to_enum(:each_instruction, type) if proc.nil?

      each do |block|
        block.each(type, &proc)
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

    def self.to_type
      SSA::FunctionType.instance
    end

    def to_value
      SSA::Constant.new(self.class.to_type, @name)
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