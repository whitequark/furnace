module Furnace
  module Transform
    module Rubinius
      class ASTBuild
        def transform(method)
          stack    = []
          map      = {}
          serial   = 0

          ast = AST::Node.new(:root)

          method.decode.each do |opcode|
            ins = opcode.instruction

            node = AST::Node.new("rbx_#{ins.opcode}")
            node.metadata[:label] = opcode.ip
            node.children += opcode.args

            # Compute the real value of consumed values.
            case ins.stack_consumed
            when Fixnum
              consumed = ins.stack_consumed
            when Array
              consumed = ins.stack_consumed[0] + opcode.args[1]
            end

            # Pop consumed values and attach to current node.
            consumed.times.map { map[stack.pop] }.reverse.each do |child|
              child.parent = node
              node.children << child
            end

            # Push back and map the results.
            if ins.stack_produced == 0 || ins.opcode == :ret
              node.parent = ast
              ast.children << node
            elsif ins.stack_produced == 1
              map[serial] = node
              stack.push serial

              serial += 1
            else
              raise RuntimeError, "don't know what to do with opcode #{opcode.inspect}"
            end
          end

          [ ast, method ]
        end
      end
    end
  end
end