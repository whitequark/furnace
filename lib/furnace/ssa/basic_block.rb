module Furnace
  class SSA::BasicBlock < SSA::NamedValue
    def initialize(function, name=nil, insns=[])
      super(function, name)
      @instructions = insns.to_a
    end

    def to_a
      @instructions.dup
    end

    def include?(instruction)
      @instructions.include? instruction
    end

    def each(&proc)
      @instructions.each(&proc)
    end

    def append(instruction)
      @instructions.push instruction
    end

    alias << append

    def insert(before, instruction)
      unless index = @instructions.index(before)
        raise ArgumentError, "Instruction #{before} is not found"
      end

      @instructions.insert index, instruction
    end

    def replace(instruction, replace_with)
      insert instruction, replace_with
      remove instruction
    end

    def remove(instruction)
      @instructions.delete instruction
    end

    def terminator
      @instructions.last
    end

    def successor_names
      control_transfer_instruction.uses.
        select do |value|
          value.type == SSA::BasicBlock
        end.map do |value|
          value.name
        end
    end

    def successors
      successor_labels.map do |label|
        @function.find(label)
      end
    end

    def predecessor_names
      predecessors.map(&:name)
    end

    def predecessors
      @function.predecessors_for(@label)
    end

    def exits?
      terminator.exits?
    end

    def type
      SSA::BasicBlock
    end

    def constant?
      true
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      p.text    @name, ":"
      p.newline

      each do |insn|
        p << '   '
        insn.pretty_print(p)
        p.newline
      end

      p
    end

    def inspect_as_value(p=SSA::PrettyPrinter.new)
      p.keyword 'label'
      p.name    name
    end
  end
end