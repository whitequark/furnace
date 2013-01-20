module Furnace
  class SSA::EventStream
    def initialize
      @types  = Hash.new { |h, k| dump_type(k) }
      @events = []
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
          operands = insn.operands.map do |basic_block, operand|
            [ dump(basic_block), dump(operand) ]
          end
        else
          operands = dump_all(insn.operands)
        end

        params = insn.pretty_parameters(SSA::PrettyPrinter.new(false)).to_s

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
      when SSA::Type
        dump_type(object)

      when SSA::Argument
        { name:  object.name,
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

      if type == SSA.void
        desc = {   kind:      "void" }
      else
        case type
        when SSA::GenericType
          desc = { kind:      "parametric",
                   name:       type.inspect,
                   parameters: dump_all(type.parameters) }

        when SSA::Type
          desc = { kind:      "monotype",
                   name:      type.inspect }

        else
          raise "Cannot dump type #{type}:#{type.class}"
        end
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
  end
end