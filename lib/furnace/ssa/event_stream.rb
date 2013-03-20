module Furnace
  class SSA::EventStream
    def initialize
      @types     = Hash.new { |h, k| dump_type(k) }
      @events    = []
      @annotator = Type::Variable::Annotator.new
    end

    def data
      @events
    end

    def add(object)
      case object
      when SSA::Instruction
        emit("add_instruction",
            name:        object.name,
            basic_block: object.basic_block.name,
            index:       object.basic_block.index(object))

        update_instruction(object)

      when SSA::BasicBlock
        emit("add_basic_block",
            name: object.name)

        object.each do |insn|
          add insn
        end

      else
        emit("add_#{object_kind(object)}",
            name: object.name)
      end
    end

    def remove(object)
      emit("remove_#{object_kind(object)}",
          name: object.name)
    end

    def rename(object, old_name)
      return if old_name.nil?

      emit("rename_#{object_kind(object)}",
          name:     old_name,
          new_name: object.name)
    end

    def set_arguments(arguments)
      emit("set_arguments",
          arguments: dump_all(arguments))
    end

    def set_return_type(return_type)
      emit("set_return_type",
          return_type: @types[return_type])
    end

    def update_instruction(insn)
      if insn.operands
        if insn.is_a? SSA::PhiInsn
          operands = Hash[insn.operands.map do |basic_block, operand|
            [ basic_block.name, dump(operand) ]
          end]
        else
          operands = dump_all(insn.operands)
        end

        params = insn.awesome_print_parameters(printer).to_s

        emit("update_instruction",
            name:       insn.name,
            opcode:     insn.opcode,
            parameters: params,
            operands:   operands,
            type:       @types[insn.type])
      else
        operands = nil
      end
    end

    def transform_start(name)
      emit("transform_start",
          name: name)
    end

    protected

    def emit(event, params={})
      @events << {
        event: event.to_s,
      }.merge(params)
    end

    def dump_all(objects)
      objects.map do |obj|
        dump obj
      end
    end

    def dump(object)
      case object
      when Type::Top
        dump_type(object)

      when SSA::Argument
        { kind:  "argument",
          name:  object.name,
          type:  @types[object.type] }

      when SSA::Constant
        { kind:  "constant",
          type:  @types[object.type],
          value: object.value.inspect }

      when SSA::Instruction,
           SSA::BasicBlock,
           SSA::Function
        { kind:  object_kind(object),
          name:  object.name }

      else
        raise "Cannot dump #{object}:#{object.class}"
      end
    end

    def dump_type(type)
      id = @types.size
      @types[type] = id

      case type
      when Type::Bottom
        desc = { kind: "void" }

      when Type::Top, Type::Variable
        desc = { kind: "monotype",
                 name: type.awesome_print(printer).to_s }

      else
        raise "Cannot dump type #{type}:#{type.class}"
      end

      @events << {
        event: "type",
        id:    id,
      }.merge(desc)

      id
    end

    def object_kind(object)
      case object
      when SSA::Instruction
        "instruction"

      when SSA::BasicBlock
        "basic_block"

      when SSA::Function
        "function"

      else
        raise "Unknown object kind for #{object.class}"
      end
    end

    protected

    def printer
      AwesomePrinter.new(false, @annotator)
    end
  end
end
