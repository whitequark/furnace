module Furnace
  class SSA::BasicBlock < SSA::NamedValue
    def initialize(function, name=nil, insns=[])
      super(function, name)
      @instructions = insns.to_a
    end

    def initialize_copy(original)
      @instructions = []
    end

    def to_a
      @instructions.dup
    end

    def include?(instruction)
      @instructions.include? instruction
    end

    def each(type=nil, &proc)
      if type.nil?
        @instructions.each(&proc)
      else
        return to_enum(:each, type) if proc.nil?

        @instructions.each do |insn|
          if insn.instance_of? type
            yield insn
          end
        end
      end
    end

    alias each_instruction each

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
      SSA::BasicBlockType.instance
    end

    def type
      self.class.to_type
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