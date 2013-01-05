require_relative 'test_helper'

describe SSA do
  SSA::PrettyPrinter.colorize = false

  class Class
    def inspect_as_type
      "^#{name}"
    end
  end

  class BindingInsn < SSA::Instruction
    def type
      Binding
    end
  end

  class DupInsn < SSA::Instruction
    def type
      operands.first.type
    end
  end

  class TupleConcatInsn < SSA::Instruction
    def type
      Array
    end
  end

  class GenericInsn < SSA::GenericInstruction
  end

  class CondBranchInsn < SSA::TerminatorInstruction
    syntax do |s|
      s.operand :condition
      s.operand :if_true,  SSA::BasicBlock
      s.operand :if_false, SSA::BasicBlock
    end

    def exits?
      false
    end
  end

  module TestScope
    include SSA

    BindingInsn = ::BindingInsn
    DupInsn = ::DupInsn
    TupleConcatInsn = ::TupleConcatInsn

    class NestedInsn < SSA::Instruction; end
  end

  class TestBuilder < SSA::Builder
    def self.scope
      TestScope
    end
  end

  before do
    @function    = SSA::Function.new('foo')
    @basic_block = SSA::BasicBlock.new(@function)
    @function.add @basic_block
  end

  def insn_noary(basic_block)
    BindingInsn.new(basic_block)
  end

  def insn_unary(basic_block, what)
    DupInsn.new(basic_block, [what])
  end

  def insn_binary(basic_block, left, right)
    TupleConcatInsn.new(basic_block, [left, right])
  end

  it 'converts class names to opcodes' do
    SSA.class_name_to_opcode(DupInsn).should == 'dup'
    SSA.class_name_to_opcode(TupleConcatInsn).should == 'tuple_concat'
    SSA.class_name_to_opcode(TestScope::NestedInsn).should == 'nested'
  end

  it 'converts opcodes to class names' do
    SSA.opcode_to_class_name('foo').should == 'FooInsn'
    SSA.opcode_to_class_name('foo_bar').should == 'FooBarInsn'
    SSA.opcode_to_class_name(:foo_bar).should == 'FooBarInsn'
  end

  describe SSA::PrettyPrinter do
    it 'outputs chunks' do
      SSA::PrettyPrinter.new do |p|
        p.text 'foo'
      end.to_s.should == 'foo'

      SSA::PrettyPrinter.new do |p|
        p.type Integer
      end.to_s.should == '^Integer'

      SSA::PrettyPrinter.new do |p|
        p.keyword 'bar'
      end.to_s.should == 'bar'
    end

    it 'ensures space between chunks' do
      SSA::PrettyPrinter.new do |p|
        p.text 'foo'
        p.keyword 'doh'
        p.text 'bar'
      end.to_s.should == 'foo doh bar'
    end

    it 'adds no space inside #text chunk' do
      SSA::PrettyPrinter.new do |p|
        p.text 'foo', 'bar'
        p.keyword 'squick'
      end.to_s.should == 'foobar squick'
    end

    it 'adds no space after newline' do
      SSA::PrettyPrinter.new do |p|
        p.text 'foo'
        p.newline
        p.text 'bar'
      end.to_s.should == "foo\nbar"
    end

    it 'converts objects to chunks with to_s' do
      SSA::PrettyPrinter.new do |p|
        p.text :foo
        p.text 1
        p.keyword :bar
      end.to_s.should == 'foo 1 bar'
    end

    it 'adds colors if requested' do
      SSA::PrettyPrinter.new(true) do |p|
        p.keyword :bar
      end.to_s.should == "\e[1;37mbar\e[0m"
    end
  end

  describe SSA::Value do
    before do
      @val = SSA::Value.new
    end

    it 'has void type' do
      @val.type.should == SSA::Void
    end

    it 'is not constant' do
      @val.should.not.be.constant
    end

    it 'compares by identity through #to_value' do
      @val.should.not == 1
      @val.should == @val

      val = @val
      @val.should == Class.new { define_method(:to_value) { val } }.new
    end

    it 'pretty prints' do
      @val.pretty_print.should =~ %r{#<Furnace::SSA::Value}
    end

    it 'has an use list' do
      other = SSA::Value.new
      @val.should.enumerate :each_use, []
      @val.should.not.be.used
      @val.use_count.should == 0

      @val.add_use(other)
      @val.should.enumerate :each_use, [other]
      @val.should.be.used
      @val.use_count.should == 1

      @val.remove_use(other)
      @val.should.enumerate :each_use, []
      @val.should.not.be.used
      @val.use_count.should == 0
    end

    it 'can have all of its uses replaced' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new(@function, [val1])

      val1.replace_all_uses_with(val2)

      val1.should.enumerate :each_use, []
      val2.should.enumerate :each_use, [user]
    end
  end

  describe SSA::Constant do
    before do
      @imm = SSA::Constant.new(Integer, 1)
    end

    it 'pretty prints' do
      @imm.pretty_print.should == '^Integer 1'
    end

    it 'converts to value' do
      @imm.to_value.should == @imm
    end

    it 'can be compared' do
      @imm.should == @imm
      @imm.should == SSA::Constant.new(Integer, 1)
      @imm.should.not == SSA::Constant.new(Integer, 2)
      @imm.should.not == SSA::Constant.new(String, 1)
      @imm.should.not == 1
    end

    it 'is constant' do
      @imm.should.be.constant
    end
  end

  describe SSA::Void do
    it 'allows to retrieve a constant' do
      const = SSA::Void.value
      const.should.be.constant
      const.type.should == SSA::Void
    end

    it 'inspects as void in constants' do
      SSA::Void.value.inspect_as_value.should == 'void'
    end
  end

  describe SSA::NamedValue do
    it 'receives unique names' do
      values = 5.times.map { SSA::NamedValue.new(@function, nil) }
      values.map(&:name).uniq.count.should == values.size
    end

    it 'receives unique names even if explicitly specified name conflicts' do
      i1 = SSA::NamedValue.new(@function, "foo")
      i2 = SSA::NamedValue.new(@function, "foo")
      i2.name.should.not == i1.name

      i2.name = 'foo'
      i2.name.should.not == i1.name
    end
  end

  describe SSA::Argument do
    before do
      @val = SSA::Argument.new(@function, nil, 'foo')
    end

    it 'pretty prints' do
      SSA::Argument.new(@function, nil, 'baz').pretty_print.
          should == '<?> %baz'

      SSA::Argument.new(@function, Integer, 'bar').pretty_print.
          should == '^Integer %bar'
    end

    it 'converts to value' do
      @val.to_value.should == @val
    end

    it 'can be compared' do
      @val.should == @val
      @val.should.not == 1
    end

    it 'compares by identity' do
      @val.should.not == SSA::Argument.new(@function, nil, 'foo')
    end

    it 'is not constant' do
      @val.should.not.be.constant
    end
  end

  describe SSA::User do
    it 'populates use lists' do
      val  = SSA::Value.new

      user = SSA::User.new(@function)
      val.should.enumerate :each_use, []

      user.operands = [val]
      val.should.enumerate :each_use, [user]
    end

    it 'updates use lists' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new(@function)
      val1.should.enumerate :each_use, []
      val2.should.enumerate :each_use, []

      user.operands = [val1]
      val1.should.enumerate :each_use, [user]
      val2.should.enumerate :each_use, []

      user.operands = [val2]
      val1.should.enumerate :each_use, []
      val2.should.enumerate :each_use, [user]
    end

    it 'detaches from values' do
      val  = SSA::Value.new
      user = SSA::User.new(@function, [val])

      val.should.enumerate :each_use, [user]
      user.detach
      val.should.enumerate :each_use, []
    end

    it 'can replace uses of values' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new(@function, [val1])
      user.replace_uses_of(val1, val2)

      val1.should.enumerate :each_use, []
      val2.should.enumerate :each_use, [user]
    end

    it 'barfs on #replace_uses_of if the value is not used' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new(@function, [val1])

      -> { user.replace_uses_of(val2, val1) }.should.raise ArgumentError
    end
  end

  describe SSA::Instruction do
    it 'is not terminator' do
      i = insn_noary(@basic_block)
      i.should.not.be.terminator
    end

    it 'removes itself from basic block' do
      i = insn_noary(@basic_block)
      @basic_block.append i

      i.remove
      @basic_block.to_a.should.be.empty
    end

    it 'replaces uses of itself with instructions' do
      i1 = insn_noary(@basic_block)
      @basic_block.append i1

      i2 = insn_unary(@basic_block, i1)
      @basic_block.append i2

      i1a = insn_noary(@basic_block)
      i1.replace_with i1a

      @basic_block.to_a.should == [i1a, i2]
      i2.operands.should == [i1a]
    end

    it 'replaces uses of itself with constants' do
      i1 = insn_noary(@basic_block)
      @basic_block.append i1

      i2 = insn_unary(@basic_block, i1)
      @basic_block.append i2

      c1 = SSA::Constant.new(Integer, 1)
      i1.replace_with c1

      @basic_block.to_a.should == [i2]
      i2.operands.should == [c1]
    end

    it 'pretty prints' do
      dup = DupInsn.new(@basic_block, [SSA::Constant.new(Integer, 1)])
      dup.pretty_print.should == '^Integer %2 = dup ^Integer 1'
      dup.inspect_as_value.should == '%2'

      concat = TupleConcatInsn.new(@basic_block,
          [SSA::Constant.new(Array, [1]), SSA::Constant.new(Array, [2,3])])
      concat.pretty_print.should == '^Array %3 = tuple_concat ^Array [1], ^Array [2, 3]'
      concat.inspect_as_value.should == '%3'

      zero_arity = BindingInsn.new(@basic_block)
      zero_arity.pretty_print.should == '^Binding %4 = binding'
      zero_arity.inspect_as_value.should == '%4'

      zero_all = TestScope::NestedInsn.new(@basic_block)
      zero_all.pretty_print.should == 'nested'
      zero_all.inspect_as_value.should == 'void'
    end

    describe SSA::GenericInstruction do
      it 'has settable type' do
        i = GenericInsn.new(@basic_block, Integer, [])
        i.pretty_print.should =~ /\^Integer %\d+ = generic/
        i.type = Binding
        i.pretty_print.should =~ /\^Binding %\d+ = generic/
      end

      describe SSA::PhiInsn do
        it 'accepts operand hash' do
          -> {
            phi = SSA::PhiInsn.new(@basic_block, nil,
                { @basic_block => SSA::Constant.new(Integer, 1) })
          }.should.not.raise
        end

        it 'pretty prints' do
          phi = SSA::PhiInsn.new(@basic_block, nil,
              { @basic_block => SSA::Constant.new(Integer, 1) })
          phi.pretty_print.should =~
            /<?> %\d = phi %\d => \^Integer 1/
        end

        it 'maintains use chains' do
          val = SSA::Value.new
          phi = SSA::PhiInsn.new(@basic_block, nil,
              { @basic_block => val })
          val.should.enumerate :each_use, [phi]
        end

        it 'can replace uses of values' do
          val1, val2 = 2.times.map { SSA::Value.new }

          phi = SSA::PhiInsn.new(@basic_block, nil,
              { @basic_block => val1 })
          phi.replace_uses_of(val1, val2)

          val1.should.enumerate :each_use, []
          val2.should.enumerate :each_use, [phi]
        end

        it 'barfs on #replace_uses_of if the value is not used' do
          val1, val2 = 2.times.map { SSA::Value.new }

          phi = SSA::PhiInsn.new(@basic_block, nil,
              { @basic_block => val1 })

          -> { phi.replace_uses_of(val2, val1) }.should.raise ArgumentError
        end
      end
    end

    describe SSA::TerminatorInstruction do
      it 'is a terminator' do
        i = SSA::TerminatorInstruction.new(@basic_block, [])
        i.should.be.terminator
      end

      it 'requires to implement #exits?' do
        i = SSA::TerminatorInstruction.new(@basic_block, [])
        -> { i.exits? }.should.raise NotImplementedError
      end

      describe SSA::BranchInsn do
        it 'does not exit the method' do
          i = SSA::BranchInsn.new(@basic_block, [@basic_block])
          i.exits?.should == false
        end
      end

      describe SSA::ReturnInsn do
        it 'exits the method' do
          i = SSA::ReturnInsn.new(@basic_block, [SSA::Void.value])
          i.exits?.should == true
        end
      end
    end
  end

  describe SSA::BasicBlock do
    it 'converts to value' do
      @basic_block.to_value.should == @basic_block
    end

    it 'has the type of BasicBlock' do
      @basic_block.type.should == SSA::BasicBlock
    end

    it 'pretty prints' do
      @basic_block.append insn_noary(@basic_block)
      @basic_block.append insn_noary(@basic_block)
      @basic_block.pretty_print.should ==
          "1:\n   ^Binding %2 = binding\n   ^Binding %3 = binding\n"
    end

    it 'inspects as value' do
      @basic_block.inspect_as_value.should == 'label %1'
    end

    it 'is constant' do
      @basic_block.constant?.should == true
    end

    it 'can append instructions' do
      i1, i2 = 2.times.map { insn_noary(@basic_block) }
      @basic_block.append i1
      @basic_block.append i2
      @basic_block.to_a.should == [i1, i2]
    end

    it 'can insert instructions' do
      i1, i2, i3 = 3.times.map { insn_noary(@basic_block) }
      @basic_block.append i1
      -> { @basic_block.insert i3, i2 }.should.raise ArgumentError, %r|is not found|
      @basic_block.append i3
      @basic_block.insert i3, i2
      @basic_block.to_a.should == [i1, i2, i3]
    end

    it 'is not affected by changes to #to_a value' do
      i1 = insn_noary(@basic_block)
      @basic_block.append i1
      @basic_block.to_a.clear
      @basic_block.to_a.size.should == 1
    end

    it 'enumerates instructions' do
      i1 = insn_noary(@basic_block)
      @basic_block.append i1
      @basic_block.should.enumerate :each, [i1]
    end

    it 'enumerates instructions by type' do
      i1 = BindingInsn.new(@basic_block)
      @basic_block.append i1

      i2 = GenericInsn.new(@basic_block)
      @basic_block.append i2

      @basic_block.each(BindingInsn).should.enumerate :each, [i1]
    end

    it 'can check for presence of instructions' do
      i1, i2 = 2.times.map { insn_noary(@basic_block) }
      @basic_block.append i1
      @basic_block.should.include i1
      @basic_block.should.not.include i2
    end

    it 'can remove instructions' do
      i1, i2 = 2.times.map { insn_noary(@basic_block) }
      @basic_block.append i1
      @basic_block.append i2
      @basic_block.remove i1
      @basic_block.to_a.should == [i2]
    end

    it 'can replace instructions' do
      i1, i2, i3, i4 = 4.times.map { insn_noary(@basic_block) }
      @basic_block.append i1
      @basic_block.append i2
      @basic_block.append i3
      @basic_block.replace i2, i4
      @basic_block.to_a.should == [i1, i4, i3]
    end

    describe 'with other blocks' do
      before do
        @branch_bb = @basic_block
        @branch_bb.name = 'branch'

        @body_bb = SSA::BasicBlock.new(@function, 'body')
        @function.add @body_bb

        @ret_bb  = SSA::BasicBlock.new(@function, 'ret')
        @function.add @ret_bb

        @cond = DupInsn.new(@branch_bb,
              [ SSA::Constant.new(TrueClass, true) ])
        @branch_bb.append @cond

        @cond_br = CondBranchInsn.new(@branch_bb,
              [ @cond,
                @body_bb,
                @ret_bb ])
        @branch_bb.append @cond_br

        @uncond_br = SSA::BranchInsn.new(@body_bb,
              [ @ret_bb ])
        @body_bb.append @uncond_br

        @ret = SSA::ReturnInsn.new(@ret_bb,
              [ SSA::Void.value ])
        @ret_bb.append @ret
      end

      it 'can determine terminator' do
        @branch_bb.terminator.should == @cond_br
        @body_bb.terminator.should == @uncond_br
        @ret_bb.terminator.should == @ret
      end

      it 'can determine successors' do
        @branch_bb.successors.should.enumerate :each, [@body_bb, @ret_bb]
        @body_bb.successors.should.enumerate :each, [@ret_bb]
        @ret_bb.successors.should.enumerate :each, []
      end

      it 'can determine predecessors' do
        @branch_bb.predecessors.should.enumerate :each, []
        @body_bb.predecessors.should.enumerate :each, [@branch_bb]
        @ret_bb.predecessors.should.enumerate :each, [@branch_bb, @body_bb]
      end

      it 'can determine predecessor names' do
        @ret_bb.predecessor_names.should.enumerate :each, %w(branch body)
      end

      it 'can determine if it is an exit block' do
        @branch_bb.exits?.should == false
        @body_bb.exits?.should == false
        @ret_bb.exits?.should == true
      end
    end
  end

  describe SSA::Function do
    it 'converts to value' do
      @function.to_value.should ==
          SSA::Constant.new(SSA::Function, @function.name)

      @function.name = 'foo'
      @function.to_value.inspect_as_value.should ==
          'function "foo"'
    end

    it 'generates numeric names in #make_name(nil)' do
      @function.make_name.should =~ /^\d+$/
    end

    it 'appends numeric suffixes in #make_name(String) if needed' do
      @function.make_name("foobar.i").should =~ /^foobar\.i$/
      @function.make_name("foobar.i").should =~ /^foobar\.i\d+$/
      @function.make_name("foobar.i").should =~ /^foobar\.i\d+$/
    end

    it 'finds blocks or raises an exception' do
      @function.find('1').should == @basic_block
      -> { @function.find('foobar') }.should.raise ArgumentError, %r|Cannot find|
    end

    it 'checks blocks for presence' do
      @function.should.include '1'
      @function.should.not.include 'foobar'
    end

    it 'removes blocks' do
      @function.remove @basic_block
      @function.should.not.include '1'
    end

    it 'iterates each instruction in each block' do
      bb2 = SSA::BasicBlock.new(@function)
      @function.add bb2

      i1 = insn_noary(@basic_block)
      @basic_block.append i1

      i2 = insn_unary(@basic_block, i1)
      bb2.append i2

      @function.should.enumerate :each_instruction, [i1, i2]
    end

    it 'pretty prints' do
      @function.name = 'foo'
      @function.arguments = [
          SSA::Argument.new(@function, Integer, 'count'),
          SSA::Argument.new(@function, Binding, 'outer')
      ]

      @basic_block.append insn_binary(@basic_block, *@function.arguments)

      bb2 = SSA::BasicBlock.new(@function, 'foo')
      @function.add bb2
      bb2.append insn_unary(@basic_block, SSA::Constant.new(Integer, 1))

      @function.pretty_print.should == <<-END
function void foo( ^Integer %count, ^Binding %outer ) {
1:
   ^Array %2 = tuple_concat %count, %outer

foo:
   ^Integer %3 = dup ^Integer 1

}
      END
    end
  end

  describe SSA::Builder do
    before do
      @b = TestBuilder.new('foo',
          [ [Integer, 'bar'], [Binding, 'baz'] ],
          Float)
      @f = @b.function
    end

    it 'has SSA as default scope' do
      SSA::Builder.scope.should == ::Furnace::SSA
    end

    it 'correctly sets function attributes' do
      @f.name.should == 'foo'
      @f.arguments.each do |arg|
        arg.function.should == @f
      end
      bar, = @f.arguments
      bar.type.should == Integer
      bar.name.should == 'bar'
      @f.return_type.should == Float

      bb = @f.find('1')
      @f.entry.should == bb
    end

    it 'appends instructions' do
      i1 = @b.append :binding
      i2 = @b.append :nested
      i1.should.be.instance_of BindingInsn
      i2.should.be.instance_of TestScope::NestedInsn
    end

    it 'dispatches through method_missing' do
      i1 = @b.binding
      i1.should.be.instance_of BindingInsn

      -> { @b.nonexistent }.should.raise NoMethodError
    end

    it 'builds ReturnInsn' do
      @b.return SSA::Void.value
      i, = @b.block.to_a
      i.should.be.instance_of SSA::ReturnInsn
      i.operands.should == [SSA::Void.value]
    end
  end

  describe SSA::InstructionSyntax do
    class SyntaxUntypedInsn < SSA::Instruction
      syntax do |s|
        s.operand :foo
        s.operand :bar
      end
    end

    class SyntaxTypedInsn < SSA::Instruction
      syntax do |s|
        s.operand :foo, Integer
      end
    end

    class SyntaxSplatInsn < SSA::Instruction
      syntax do |s|
        s.operand :foo
        s.splat   :bars
      end
    end

    before do
      @iconst = SSA::Constant.new(Integer, 1)
      @fconst = SSA::Constant.new(Float, 1.0)
      @iinsn  = DupInsn.new(@basic_block, [ @iconst ])
    end

    it 'accepts operands and decomposes them' do
      i = SyntaxUntypedInsn.new(@basic_block, [ @iconst, @fconst ])
      i.foo.should == @iconst
      i.bar.should == @fconst
    end

    it 'allows to change operands through accessors' do
      i = SyntaxUntypedInsn.new(@basic_block, [ @iconst, @fconst ])
      i.foo = @iinsn
      i.operands.should == [@iinsn, @fconst]
    end

    it 'does not accept wrong amount of operands' do
      -> { SyntaxUntypedInsn.new(@basic_block, [ @iconst ]) }.
        should.raise ArgumentError
      -> { SyntaxUntypedInsn.new(@basic_block, [ @iconst, @iconst, @iconst ]) }.
        should.raise ArgumentError
    end

    it 'accepts only correct typed operands' do
      -> { SyntaxTypedInsn.new(@basic_block, [ @fconst ]) }.
        should.raise TypeError
      -> { SyntaxTypedInsn.new(@basic_block, [ @iconst ]) }.
        should.not.raise
      -> { SyntaxTypedInsn.new(@basic_block, [ @iinsn ]) }.
        should.not.raise
    end

    it 'accepts splat' do
      i = SyntaxSplatInsn.new(@basic_block, [ @iconst, @fconst, @iinsn ])
      i.foo.should == @iconst
      i.bars.should == [@fconst, @iinsn]
    end

    it 'does not accept wrong amount of operands with splat' do
      -> { SyntaxSplatInsn.new(@basic_block, []) }.
          should.raise ArgumentError
    end

    it 'only permits one last splat' do
      -> {
        Class.new(SSA::Instruction) {
          syntax do |s|
            s.splat   :bars
            s.operand :foo
          end
        }
      }.should.raise ArgumentError

      -> {
        Class.new(SSA::Instruction) {
          syntax do |s|
            s.splat :bars
            s.splat :foos
          end
        }
      }.should.raise ArgumentError
    end

    it 'allows to inquire status' do
      i = SyntaxTypedInsn.new(@basic_block, [ @iconst ])
      i.should.be.valid
      i.foo = @fconst
      i.should.not.be.valid
    end

    it 'allows to treat nil type as error' do
      phi = SSA::PhiInsn.new(@basic_block, nil)

      i   = SyntaxTypedInsn.new(@basic_block, [ @iconst ])
      i.should.be.valid(true)
      i.should.be.valid(false)
      -> { i.verify!(false) }.should.not.raise

      i.foo = phi
      i.should.be.valid(true)
      i.should.not.be.valid(false)
      -> { i.verify!(false) }.should.raise TypeError, %r|<?>|
    end
  end

  describe SSA::Module do
    before do
      @module = SSA::Module.new
    end

    it 'adds named functions' do
      f = SSA::Function.new('foo')
      @module.add f
      @module.to_a.should == [f]
      f.name.should == 'foo'
    end

    it 'adds unnamed functions and names them' do
      f = SSA::Function.new
      @module.add f
      f.name.should.not == nil
    end

    it 'adds named functions with explicit prefix' do
      f = SSA::Function.new('foo')
      @module.add f, 'bar'
      f.name.should == 'bar$1'
    end

    it 'automatically renames functions with duplicate names' do
      f1 = SSA::Function.new('foo')
      @module.add f1

      f2 = SSA::Function.new('foo')
      @module.add f2
      f2.name.should == 'foo$1'
    end

    it 'retrieves functions' do
      f1 = SSA::Function.new('foo')
      @module.add f1
      @module['foo'].should == f1
      -> { @module['bar'] }.should.raise ArgumentError
    end

    it 'enumerates functions' do
      f1 = SSA::Function.new('foo')
      @module.add f1
      f2 = SSA::Function.new('bar')
      @module.add f2

      @module.should.enumerate :each, [f1, f2]
    end

    it 'removes functions' do
      f1 = SSA::Function.new('foo')
      @module.add f1
      @module.should.include 'foo'
      @module.remove 'foo'
      @module.should.not.include 'foo'
    end
  end
end