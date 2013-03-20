module Furnace
  class SSA::BasicBlock < SSA::NamedValue
    def initialize(function, name=nil, insns=[])
      super(function, name)
      @instructions = insns.to_a
    end

    def initialize_copy(original)
      super

      @instructions = []
    end

    def to_a
      @instructions.dup
    end

    def include?(instruction)
      @instructions.include? instruction
    end

    def each(*types, &proc)
      if types.empty?
        @instructions.each(&proc)
      else
        return to_enum(:each, *types) if proc.nil?

        @instructions.each do |insn|
          if types.include?(insn.class)
            yield insn
          end
        end
      end
    end

    alias each_instruction each

    def prepend(instruction)
      @instructions.unshift instruction

      instrument { |i| i.add instruction }
    end

    def append(instruction)
      @instructions.push instruction

      instrument { |i| i.add instruction }
    end

    alias << append

    def index(instruction)
      @instructions.index(instruction)
    end

    def insert(before, instruction)
      unless (idx = index(before))
        raise ArgumentError, "Instruction #{before} is not found"
      end

      @instructions.insert idx, instruction

      instrument { |i| i.add instruction }
    end

    def replace(instruction, replace_with)
      insert instruction, replace_with
      remove instruction
    end

    def remove(instruction)
      @instructions.delete instruction

      instrument { |i| i.remove instruction }
    end

    def splice(after)
      unless (idx = index(after))
        raise ArgumentError, "Instruction #{after} is not found"
      end

      result = []

      @instructions[idx + 1..-1].each do |insn|
        result << insn
        remove insn
      end

      result
    end

    def terminator
      @instructions.last
    end

    def successor_names
      terminator.successors
    end

    def successors
      successor_names.map do |label|
        @function.find(label)
      end
    end

    def predecessor_names
      predecessors.map(&:name)
    end

    def predecessors
      @function.predecessors_for(@name)
    end

    def exits?
      terminator.exits?
    end

    def self.to_type
      SSA::BasicBlockType.new
    end

    def type
      self.class.to_type
    end

    def constant?
      true
    end

    def awesome_print(p=AwesomePrinter.new)
      p.text(@name).
        append(":").
        newline

      p.collection(@instructions) do |insn|
        p.append('   ').
          nest(insn).
          newline
      end

      p.newline
    end

    def inspect_as_value(p=AwesomePrinter.new)
      p.keyword('label').
        name(name)
    end

    protected

    def instrument(&block)
      @function.instrument(&block) if @function
    end
  end
end
