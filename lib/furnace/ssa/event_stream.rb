module Furnace
  class SSA::EventStream
    def initialize
      @events    = []
      @types     = Set[]
      @annotator = Type::Variable::Annotator.new
    end

    def data
      @events
    end

    def process(object)
      case object
      # Types
      when Type::Bottom
        event = {
          kind:             "type_bottom",
          name:             "bottom",
        }

      when Type::Top
        event = {
          kind:             "type",
          name:             object.awesome_print(printer),
        }

      when Type::Variable
        event = {
          kind:             "type_variable",
          name:             object.awesome_print(printer).to_s,
        }

      # Entities
      when SSA::Constant
        event = {
          kind:             "constant",
          type:             type(object.type),
          value:            object.value.inspect,
        }

      when SSA::Argument
        event = {
          kind:             "argument",
          name:             object.name,
          type:             type(object.type),
        }

      when SSA::BasicBlock
        event = {
          kind:             "basic_block",
          name:             object.name,
          instruction_ids:  ids(object.each),
        }

      when SSA::PhiInsn
        event = {
          kind:             "phi",
          operand_ids:      object.operands.map do |block, value|
                              [ id(block), id(value) ]
                            end,
        }

      when SSA::Instruction
        event = {
          kind:             "instruction",
          name:             object.name,
          opcode:           object.opcode,
          type:             type(object.type),
          operand_ids:      object.operands.map(&:object_id),
        }

      when SSA::Function
        event = {
          kind:             "function",
          name:             object.name,
          argument_ids:     ids(object.arguments),
          return_type:      type(object.return_type),
          entry_id:         id(object.entry),
          basic_block_ids:  ids(object.each),
        }

      when SSA::Module
        event = {
          kind:             "module",
          function_ids:     ids(object.each),
        }

      else
        raise "Cannot instrument #{object.class}"
      end

      @events << { id: id(object) }.merge(event)

      nil
    end

    def mark_transform(function, name)
      @events << {
        kind:        "transform",
        function_id: id(function),
        name:        name
      }
    end

    protected

    def id(object)
      if object
        object.object_id
      end
    end

    def ids(objects)
      objects.map do |object|
        id(object)
      end
    end

    def type(type)
      if @types.include?(type)
        type.object_id
      else
        @types.add type

        process(type)

        type.object_id
      end
    end

    def printer
      AwesomePrinter.new(false, @annotator)
    end
  end
end
