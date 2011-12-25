module Furnace
  module Transform
    module Rubinius
      class ASTNormalize
        include AST::Visitor

        def transform(ast, method)
          @locals = method.local_names

          visit ast

          [ ast, method ]
        end

        # (rbx-meta-push-0) -> 0
        def on_rbx_meta_push_0(node)
          node.update(:fixnum, [0], :constant => true)
        end

        # (rbx-meta-push-1) -> 1
        def on_rbx_meta_push_1(node)
          node.update(:fixnum, [1], :constant => true)
        end

        # (rbx-meta-push-2) -> 2
        def on_rbx_meta_push_2(node)
          node.update(:fixnum, [2], :constant => true)
        end

        # (rbx-push-int x) -> x
        def on_rbx_push_int(node)
          node.update(:fixnum, nil, :constant => true)
        end

        # (rbx-push-nil) -> (nil)
        def on_rbx_push_nil(node)
          node.update(:nil, nil, :constant => true)
        end

        # (rbx-pop x) -> x
        def on_rbx_pop(node)
          child = node.children.first
          child.update(:nop) if child.metadata[:constant]

          node.update(:expand, [
            child,
            AST::Node.new(:jump_target, [], node.metadata)
          ], nil)
        end

        # (rbx-*) -> .
        def make_jump_target(node)
          node.update(:jump_target)
        end
        alias :on_rbx_check_interrupts :make_jump_target
        alias :on_rbx_allow_private :make_jump_target

        # (rbx-push-self) -> (self)
        def on_rbx_push_self(node)
          node.update(:self)
        end

        # (rbx-push-local x) -> (get-local x)
        def on_rbx_push_local(node)
          node.update(:get_local, [@locals[node.children.first]])
        end

        # (rbx-set-local x) -> (set-local x)
        def on_rbx_set_local(node)
          node.update(:set_local, [@locals[node.children.first], node.children.last])
        end

        # (rbx-ret x) -> (return x)
        def on_rbx_ret(node)
          node.update(:return)
        end

        # (rbx-send-method msg receiver) -> (send msg receiver)
        def on_rbx_send_method(node)
          node.update(:send, [
            AST::MethodName.new(node.children[0]),
            node.children[1]
          ])
        end

        # (rbx-send-stack msg count receiver args...) -> (send msg receiver args...)
        def on_rbx_send_stack(node)
          node.update(:send, [
            AST::MethodName.new(node.children[0]),  # message
            node.children[2],                       # receiver
            *node.children[3..-1]                   # args
          ])
        end

        # (rbx-send-stack-with-block msg count receiver args... block) -> (send-with-block msg receiver args... block)
        def on_rbx_send_stack_with_block(node)
          node.update(:send_with_block, [
            AST::MethodName.new(node.children[0]),  # message
            node.children[2],                       # receiver
            *node.children[3..-1]                   # args
          ])
        end

        # (rbx-create-block block) -> (lambda block)
        def on_rbx_create_block(node)
          $block = node.children.first
          node.update(:lambda, ["FAIL"])
        end

        # (rbx-meta-send-op-* op receiver arg) -> (send op receiver arg)
        def on_rbx_send_op_any(node)
          node.update(:send, [
            AST::MethodName.new(node.children[0]),
            node.children[1..-1]
          ])
        end
        alias :on_rbx_meta_send_op_plus :on_rbx_send_op_any
        alias :on_rbx_meta_send_op_minus :on_rbx_send_op_any
        alias :on_rbx_meta_send_op_gt :on_rbx_send_op_any
        alias :on_rbx_meta_send_op_lt :on_rbx_send_op_any

        # (rbx-goto-if-* block condition) -> (jump-if block value condition)
        def on_rbx_goto_if_false(node)
          node.update(:jump_if, [node.children[0], false, node.children[1]])
        end

        def on_rbx_goto_if_true(node)
          node.update(:jump_if, [node.children[0], true, node.children[1]])
        end

        # (rbx-goto block) -> (jump block)
        def on_rbx_goto(node)
          node.update(:jump)
        end
      end
    end
  end
end