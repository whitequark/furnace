module Furnace
  class SSA::Function
    attr_accessor :instrumentation

    attr_reader   :original_name
    attr_reader   :name
    attr_reader   :arguments
    attr_reader   :return_type

    attr_accessor :entry

    def initialize(name=nil, arguments=[], return_type=SSA.void, instrument=nil)
      @original_name   = name
      @instrumentation = instrument
      self.name        = name
      self.arguments   = arguments
      self.return_type = return_type

      @basic_blocks  = Set.new

      @name_prefixes = [""].to_set
      @next_name     = 0
    end

    def initialize_copy(original)
      @name = @original_name

      if @instrumentation
        @instrumentation = SSA::EventStream.new
      end

      value_map = Hash.new do |value_map, value|
        new_value = value.dup
        value_map[value] = new_value

        if new_value.is_a? SSA::User
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

    def name=(name)
      @name = name
    end

    def arguments=(arguments)
      @arguments = sanitize_arguments(arguments)
      instrument { |i| i.set_arguments @arguments }
    end

    def return_type=(return_type)
      @return_type = return_type.to_type if return_type
      instrument { |i| i.set_return_type @return_type }
    end

    def make_name(prefix=nil)
      if prefix.nil?
        (@next_name += 1).to_s
      else
        prefix = prefix.to_s

        if @name_prefixes.include? prefix
          "#{prefix}.#{@next_name += 1}"
        else
          @name_prefixes.add prefix
          prefix
        end
      end
    end

    def each(&proc)
      @basic_blocks.each(&proc)
    end

    alias each_basic_block each

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
      instrument { |i| i.add block }
    end

    alias << add

    def remove(block)
      @basic_blocks.delete block
      instrument { |i| i.remove block }
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

    alias inspect pretty_print

    def instrument
      yield @instrumentation if @instrumentation
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