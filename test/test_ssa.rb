require_relative 'helper'

describe SSA do
  AwesomePrinter.colorize = false

  class BindingInsn < SSA::Instruction
    def type
      Binding.to_type
    end
  end

  class DupInsn < SSA::Instruction
    def type
      operands.first.type
    end
  end

  class TupleConcatInsn < SSA::Instruction
    def type
      Array.to_type
    end
  end

  class GenericInsn < SSA::GenericInstruction
  end

  class CondBranchInsn < SSA::TerminatorInstruction
    syntax do |s|
      s.operand :condition
      s.operand :if_true
      s.operand :if_false
    end

    def exits?
      false
    end
  end

  class IsBInsn < SSA::Instruction
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
    @basic_block = SSA::BasicBlock.new
    @function.add @basic_block
    @function.entry = @basic_block
  end

  def insn_noary
    BindingInsn.new
  end

  def insn_unary(what)
    DupInsn.new([what])
  end

  def insn_binary(left, right)
    TupleConcatInsn.new([left, right])
  end

  it 'converts class names to opcodes' do
    SSA.class_name_to_opcode(DupInsn).should == 'dup'
    SSA.class_name_to_opcode(TupleConcatInsn).should == 'tuple_concat'
    SSA.class_name_to_opcode(TestScope::NestedInsn).should == 'nested'
    SSA.class_name_to_opcode(IsBInsn).should == 'is_b'
  end

  it 'converts opcodes to class names' do
    SSA.opcode_to_class_name('foo').should == 'FooInsn'
    SSA.opcode_to_class_name('foo_bar').should == 'FooBarInsn'
    SSA.opcode_to_class_name(:foo_bar).should == 'FooBarInsn'
    SSA.opcode_to_class_name(:is_b).should == 'IsBInsn'
  end

  describe SSA::Value do
    before do
      @val = SSA::Value.new
    end

    it 'has bottom type' do
      @val.type.should == Type::Bottom.new
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
      @val.awesome_print.should =~ %r{#<Furnace::SSA::Value}
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

      user = SSA::User.new([val1])

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
      @imm.awesome_print.should == '^Integer 1'
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

  describe SSA::NamedValue do
    it 'receives unique names' do
      values = 5.times.map do
        v = SSA::NamedValue.new(nil)
        v.function = @function
        v
      end

      values.map(&:name).uniq.size.should == 5
    end

    it 'receives unique names even if explicitly specified name conflicts' do
      i1 = SSA::NamedValue.new("foo")
      i1.function = @function

      i2 = SSA::NamedValue.new("foo")
      i2.name.should == i1.name

      i2.function = @function
      i2.name.should.not == i1.name
    end
  end

  describe SSA::Argument do
    before do
      @val = SSA::Argument.new(Integer, 'foo')
    end

    it 'converts to value' do
      @val.to_value.should == @val
    end

    it 'can be compared' do
      @val.should == @val
      @val.should.not == 1
    end

    it 'compares by identity' do
      @val.should.not == SSA::Argument.new(Integer, 'foo')
    end

    it 'is not constant' do
      @val.should.not.be.constant
    end

    it 'replaces its type' do
      ty = Type::Variable.new

      val = SSA::Argument.new(ty, 'foo')
      val.replace_type_with(ty, Integer.to_type)
      val.type.should == Integer.to_type
    end

    it 'pretty prints' do
      @val.awesome_print.
          should == '^Integer %foo'
    end
  end

  describe SSA::User do
    it 'enumerates operands' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new([val1, val2])
      user.should.enumerate :each_operand, [val1, val2]
    end

    it 'populates use lists' do
      val  = SSA::Value.new

      user = SSA::User.new
      val.should.enumerate :each_use, []

      user.operands = [val]
      val.should.enumerate :each_use, [user]
    end

    it 'updates use lists' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new
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
      user = SSA::User.new([val])

      val.should.enumerate :each_use, [user]
      user.drop_references
      val.should.enumerate :each_use, []
    end

    it 'can replace uses of values' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new([val1])
      user.replace_uses_of(val1, val2)

      val1.should.enumerate :each_use, []
      val2.should.enumerate :each_use, [user]
    end

    it 'barfs on #replace_uses_of if the value is not used' do
      val1, val2 = 2.times.map { SSA::Value.new }

      user = SSA::User.new([val1])

      -> { user.replace_uses_of(val2, val1) }.should.raise ArgumentError
    end
  end

  describe SSA::Instruction do
    it 'is not terminator' do
      i = insn_noary
      i.should.not.be.terminator
    end

    it 'does not have side effects' do
      i = insn_noary
      i.has_side_effects?.should == false
    end

    it 'removes itself from basic block' do
      i = insn_noary
      @basic_block.append i

      i.remove
      @basic_block.to_a.should.be.empty
      i.awesome_print.should =~ /\^Binding %\d+ = binding/

      i.erase
      i.awesome_print.should =~ /\^Binding %\d+ = binding <DETACHED>/
    end

    it 'replaces uses of itself with instructions' do
      i1 = insn_noary
      @basic_block.append i1

      i2 = insn_unary(i1)
      @basic_block.append i2

      i1a = insn_noary
      i1.replace_with i1a

      @basic_block.to_a.should == [i1a, i2]
      i2.operands.should == [i1a]
    end

    it 'replaces uses of itself with constants' do
      i1 = insn_noary
      @basic_block.append i1

      i2 = insn_unary(i1)
      @basic_block.append i2

      c1 = SSA::Constant.new(Integer, 1)
      i1.replace_with c1

      @basic_block.to_a.should == [i2]
      i2.operands.should == [c1]
    end

    it 'pretty prints' do
      dup = DupInsn.new([SSA::Constant.new(Integer, 1)])
      dup.basic_block = @basic_block
      dup.awesome_print.should =~ /\^Integer %\d+ = dup \^Integer 1/
      dup.awesome_print_as_value.should =~ /^%\d+/

      concat = TupleConcatInsn.new(
          [SSA::Constant.new(Array, [1]), SSA::Constant.new(Array, [2,3])])
      concat.basic_block = @basic_block
      concat.awesome_print.should =~ /\^Array %\d+ = tuple_concat \^Array \[1\], \^Array \[2, 3\]/
      concat.awesome_print_as_value.should =~ /^%\d+/

      zero_arity = BindingInsn.new
      zero_arity.basic_block = @basic_block
      zero_arity.awesome_print.should =~ /\^Binding %\d+ = binding/
      zero_arity.awesome_print_as_value.should =~ /^%\d+/

      zero_all = TestScope::NestedInsn.new
      zero_all.basic_block = @basic_block
      zero_all.awesome_print.should == 'nested'
      zero_all.awesome_print_as_value.should == 'bottom'
    end

    describe SSA::GenericInstruction do
      it 'has settable type' do
        i = GenericInsn.new(Integer, [])
        i.basic_block = @basic_block
        i.awesome_print.should =~ /\^Integer %\d+ = generic/
        i.type = Binding
        i.awesome_print.should =~ /\^Binding %\d+ = generic/
      end

      it 'replaces its type' do
        ty = Type::Variable.new

        i = GenericInsn.new(ty, [])
        i.replace_type_with(ty, Integer.to_type)
        i.type.should == Integer.to_type
      end

      describe SSA::PhiInsn do
        it 'accepts operand hash' do
          -> {
            phi = SSA::PhiInsn.new(Integer,
                { @basic_block => SSA::Constant.new(Integer, 1) })
          }.should.not.raise
        end

        it 'enumerates operands' do
          val1, val2 = 2.times.map { SSA::Value.new }
          bb1,  bb2  = 2.times.map { SSA::BasicBlock.new }

          phi = SSA::PhiInsn.new(Integer,
              { bb1 => val1, bb2 => val2 })
          phi.should.enumerate :each_operand, [val1, val2, bb1, bb2]
        end

        it 'pretty prints' do
          phi = SSA::PhiInsn.new(Integer,
              { @basic_block => SSA::Constant.new(Integer, 1) })
          phi.basic_block = @basic_block
          phi.awesome_print.should =~
            /\^Integer %\d = phi %\d => \^Integer 1/
        end

        it 'maintains use chains' do
          val = SSA::Value.new
          phi = SSA::PhiInsn.new(Integer,
                    { @basic_block => val })
          val.should.enumerate :each_use, [phi]
          @basic_block.should.enumerate :each_use, [phi]
        end

        it 'can replace uses of values' do
          val1, val2 = 2.times.map { SSA::Value.new }

          phi = SSA::PhiInsn.new(Integer,
                    { @basic_block => val1 })
          phi.replace_uses_of(val1, val2)

          val1.should.enumerate :each_use, []
          val2.should.enumerate :each_use, [phi]
        end

        it 'can replace uses of basic blocks' do
          val = SSA::Value.new
          bb2 = SSA::BasicBlock.new

          phi = SSA::PhiInsn.new(Integer,
              { @basic_block => val })
          phi.replace_uses_of(@basic_block, bb2)

          phi.operands.should == { bb2 => val }
          @basic_block.should.enumerate :each_use, []
          bb2.should.enumerate :each_use, [phi]
        end

        it 'barfs on #replace_uses_of if the value is not used' do
          val1, val2 = 2.times.map { SSA::Value.new }

          phi = SSA::PhiInsn.new(Integer,
              { @basic_block => val1 })

          -> { phi.replace_uses_of(val2, val1) }.should.raise ArgumentError
        end
      end
    end

    describe SSA::TerminatorInstruction do
      it 'is a terminator' do
        i = SSA::TerminatorInstruction.new([])
        i.should.be.terminator
      end

      it 'has side effects if exits?' do
        i = SSA::TerminatorInstruction.new([])

        def i.exits?; true; end
        i.has_side_effects?.should == true
      end

      it 'requires to implement #exits?' do
        i = SSA::TerminatorInstruction.new([])
        -> { i.exits? }.should.raise NotImplementedError
      end

      describe SSA::BranchInsn do
        it 'does not exit the method' do
          i = SSA::BranchInsn.new([@basic_block])
          i.exits?.should == false
        end
      end

      describe SSA::ReturnInsn do
        before do
          @i = SSA::ReturnInsn.new
        end

        it 'exits the method' do
          @i.exits?.should == true
        end

        it 'returns bottom in #value_type' do
          @i.value_type.should == Type::Bottom.new
        end
      end

      describe SSA::ReturnValueInsn do
        before do
          @i = SSA::ReturnValueInsn.new([SSA::Constant.new(Integer, 1)])
        end

        it 'exits the method' do
          @i.exits?.should == true
        end

        it 'returns value type in #value_type' do
          @i.value_type.should == Integer.to_type
        end
      end
    end
  end

  describe SSA::BasicBlock do
    it 'converts to value' do
      @basic_block.to_value.should == @basic_block
    end

    it 'has the type of BasicBlock' do
      @basic_block.type.should == SSA::BasicBlockType.new
    end

    it 'pretty prints' do
      @basic_block.append insn_noary
      @basic_block.append insn_noary
      @basic_block.awesome_print.should ==
          "1:\n   ^Binding %2 = binding\n   ^Binding %3 = binding\n\n"
    end

    it 'inspects as value' do
      @basic_block.awesome_print_as_value.should == 'label %1'
    end

    it 'is constant' do
      @basic_block.constant?.should == true
    end

    it 'can append instructions' do
      i1, i2 = 2.times.map { insn_noary }
      @basic_block.append i1
      @basic_block.append i2
      @basic_block.to_a.should == [i1, i2]
    end

    it 'can prepend instructions' do
      i1, i2 = 2.times.map { insn_noary }
      @basic_block.prepend i1
      @basic_block.prepend i2
      @basic_block.to_a.should == [i2, i1]
    end

    it 'can insert instructions' do
      i1, i2, i3 = 3.times.map { insn_noary }
      @basic_block.append i1
      -> { @basic_block.insert i3, i2 }.should.raise ArgumentError, %r|is not found|
      @basic_block.append i3
      @basic_block.insert i3, i2
      @basic_block.to_a.should == [i1, i2, i3]
    end

    it 'can splice instructions' do
      i1, i2, i3 = 3.times.map { insn_noary }
      @basic_block.append i1
      @basic_block.append i2
      @basic_block.append i3
      @basic_block.splice(i2).should == [i3]
      @basic_block.to_a.should == [i1, i2]

      -> { @basic_block.splice(i3) }.should.raise(ArgumentError, %r|is not found|)
    end

    it 'is not affected by changes to #to_a value' do
      i1 = insn_noary
      @basic_block.append i1
      @basic_block.to_a.clear
      @basic_block.to_a.size.should == 1
    end

    it 'enumerates instructions' do
      i1 = insn_noary
      @basic_block.append i1
      @basic_block.should.enumerate :each, [i1]
    end

    it 'enumerates instructions by type' do
      i1 = BindingInsn.new
      @basic_block.append i1

      i2 = GenericInsn.new(Integer)
      @basic_block.append i2

      @basic_block.each(BindingInsn).should.enumerate :each, [i1]
    end

    it 'can check for presence of instructions' do
      i1, i2 = 2.times.map { insn_noary }
      @basic_block.append i1
      @basic_block.should.include i1
      @basic_block.should.not.include i2
    end

    it 'can remove instructions' do
      i1, i2 = 2.times.map { insn_noary }
      @basic_block.append i1
      @basic_block.append i2
      @basic_block.remove i1
      @basic_block.to_a.should == [i2]
    end

    it 'can replace instructions' do
      i1, i2, i3, i4 = 4.times.map { insn_noary }
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

        @body_bb = SSA::BasicBlock.new([], 'body')
        @function.add @body_bb

        @ret_bb  = SSA::BasicBlock.new([], 'ret')
        @function.add @ret_bb

        @cond = DupInsn.new([ SSA::Constant.new(TrueClass, true) ])
        @branch_bb.append @cond

        @cond_br = CondBranchInsn.new(
              [ @cond,
                @body_bb,
                @ret_bb ])
        @branch_bb.append @cond_br

        @uncond_br = SSA::BranchInsn.new(
              [ @ret_bb ])
        @body_bb.append @uncond_br

        @ret = SSA::ReturnInsn.new
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
      @function.to_value.awesome_print_as_value.should ==
          'function "foo"'
    end

    it 'converts to type' do
      SSA::Function.to_type.should == SSA::FunctionType.new
    end

    it 'generates numeric names in #make_name(nil)' do
      @function.make_name.should =~ /^\d+$/
    end

    it 'appends numeric suffixes in #make_name(String) if needed' do
      @function.make_name("foobar.i").should =~ /^foobar\.i$/
      @function.make_name("foobar.i").should =~ /^foobar\.i\.\d+$/
      @function.make_name("foobar.i").should =~ /^foobar\.i\.\d+$/
    end

    it 'finds blocks or raises an exception' do
      @function.find('1').should == @basic_block
      -> { @function.find('foobar') }.should.raise ArgumentError, %r|Cannot find|
    end

    it 'checks blocks for presence' do
      @function.should.include '1'
      @function.should.not.include 'foobar'
    end

    it 'reports #size' do
      @function.size.should == 1
    end

    it 'removes blocks' do
      @function.remove @basic_block
      @function.should.not.include '1'
    end

    it 'iterates each instruction in each block' do
      bb2 = SSA::BasicBlock.new
      @function.add bb2

      i1 = insn_noary
      @basic_block.append i1

      i2 = insn_unary(i1)
      bb2.append i2

      @function.should.enumerate :each_instruction, [i1, i2]
    end

    it 'sanitizes arguments' do
      -> { @function.arguments = [1] }.should.raise(ArgumentError)
    end

    it 'pretty prints' do
      @function.name = 'foo'
      @function.arguments = [
          SSA::Argument.new(Integer, 'count'),
          SSA::Argument.new(Binding, 'outer')
      ]

      @basic_block.append insn_binary(*@function.arguments)

      bb2 = SSA::BasicBlock.new([], 'foo')
      @function.add bb2
      bb2.append insn_unary(SSA::Constant.new(Integer, 1))

      @function.awesome_print.should == <<-END
function bottom foo (^Integer %count, ^Binding %outer) {
1:
   ^Array %2 = tuple_concat %count, %outer

foo:
   ^Integer %3 = dup ^Integer 1

}
      END
    end

    it 'duplicates all its content' do
      @function.name = 'foo;1'
      @function.arguments = [
          SSA::Argument.new(Integer, 'count'),
      ]

      f1a1 = @function.arguments.first

      f1bb1 = @function.entry
      f1bb1.name = 'bb1'

      f1bb2 = SSA::BasicBlock.new([], 'bb2')
      @function.add f1bb2

      f1i1 = insn_unary(f1a1)
      @basic_block.append f1i1

      f1c1 = SSA::Constant.new(Array, [1])
      f1i2 = insn_binary(f1i1, f1c1)
      f1bb2.append f1i2

      f1bb3 = SSA::BasicBlock.new([], 'bb3')
      @function.add f1bb3

      f1phi = SSA::PhiInsn.new(Integer,
          { f1bb1 => f1i1, f1bb2 => f1i2 })
      f1bb3.append f1phi

      f1 = @function
      f2 = @function.dup

      (f1.arguments & f2.arguments).should.be.empty
      (f1.each.to_a & f2.each.to_a).should.be.empty
      (f1.each_instruction.to_a & f2.each_instruction.to_a).should.be.empty
      f2.original_name.should == f1.original_name
      f2.name.should == f1.original_name

      f1.entry.should.not == f2.entry

      f2a1  = f2.arguments.first

      f2bb1 = f2.find 'bb1'
      f2i1  = f2bb1.to_a.first
      f2bb2 = f2.find 'bb2'
      f2i2  = f2bb2.to_a.first
      f2bb3 = f2.find 'bb3'
      f2phi = f2bb3.to_a.first

      f2.entry.should == f2bb1
      f2i1.operands.should == [f2a1]
      f2a1.should.enumerate :each_use, [f2i1]
      f2i2.operands.should == [f2i1, f1c1]
      f2i1.should.enumerate :each_use, [f2i2, f2phi]

      f1a1.should.enumerate :each_use, [f1i1]
      f1i1.should.enumerate :each_use, [f1i2, f1phi]

      f2.arguments.each do |arg|
        arg.function.should == f2
      end

      f2.each_instruction do |insn|
        insn.function.should == f2
        f2.each.to_a.should.include insn.basic_block
      end

      f2.name = f1.name
      f2.awesome_print.to_s.should == f1.awesome_print.to_s
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
      bar.type.should == Integer.to_type
      bar.name.should == 'bar'
      @f.return_type.should == Float.to_type

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
      @b.return
      i, = @b.block.to_a
      i.should.be.instance_of SSA::ReturnInsn
      i.operands.should == []
    end

    it 'builds ReturnValueInsn' do
      v1 = SSA::Constant.new(Integer, 1)

      @b.return_value v1
      i, = @b.block.to_a
      i.should.be.instance_of SSA::ReturnValueInsn
      i.operands.should == [v1]
    end
  end

  describe SSA::InstructionSyntax do
    class SyntaxUntypedInsn < SSA::Instruction
      syntax do |s|
        s.operand :foo
        s.operand :bar
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
      @iinsn  = DupInsn.new([ @iconst ])
    end

    it 'accepts operands and decomposes them' do
      i = SyntaxUntypedInsn.new([ @iconst, @fconst ])
      i.foo.should == @iconst
      i.bar.should == @fconst
    end

    it 'allows to change operands through accessors' do
      i = SyntaxUntypedInsn.new([ @iconst, @fconst ])
      i.foo = @iinsn
      i.operands.should == [@iinsn, @fconst]
    end

    it 'does not accept wrong amount of operands' do
      -> { SyntaxUntypedInsn.new([ @iconst ]) }.
        should.raise ArgumentError
      -> { SyntaxUntypedInsn.new([ @iconst, @iconst, @iconst ]) }.
        should.raise ArgumentError
    end

    it 'accepts splat' do
      i = SyntaxSplatInsn.new([ @iconst, @fconst, @iinsn ])
      i.foo.should == @iconst
      i.bars.should == [@fconst, @iinsn]
    end

    it 'does not accept wrong amount of operands with splat' do
      -> { SyntaxSplatInsn.new([]) }.
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

    it 'allows to update splat' do
      i = SyntaxSplatInsn.new([ @iconst, @fconst, @iinsn ])
      i.bars = [@iinsn, @fconst]
      i.bars.should == [@iinsn, @fconst]
      i.operands.should == [@iconst, @iinsn, @fconst]
    end

    it 'does not interfere with def-use tracking' do
      i = SyntaxUntypedInsn.new([ @iconst, @fconst ])
      @fconst.should.enumerate :each_use, [ i ]

      i.bar = @iinsn
      @fconst.should.enumerate :each_use, []
      @iinsn.should.enumerate :each_use, [ i ]
    end

    it 'does not break on replace_uses_of' do
      i = SyntaxUntypedInsn.new([ @iconst, @fconst ])
      i.replace_uses_of @iconst, @fconst
      i.foo.should == @fconst
    end
  end

  describe SSA::EventStream do
    before do
      @b   = TestBuilder.new('foo',
              [ [Integer, 'bar'], [Binding, 'baz'] ],
              Float,
              instrument: true)
      @fun = @b.function
      @es  = @fun.instrumentation

      @mod  = SSA::Module.new
      @mod.add @fun
    end

    it 'instruments functions' do
      iconst  = SSA::Constant.new(Integer, 1)
      iconst2 = @b.append :dup, [ iconst ]

      iconst2.name = 'dupped'

      @b.add_block do
        @b.return_value iconst2
      end

      @es.transform_start("footrans")
      @fun.remove @b.block

      @mod.instrumentation.should ==
      [{:name=>"foo",
        :events=>
         [{:event=>"set_arguments", :arguments=>[]},
          {:event=>"type", :id=>0, :kind=>"monotype", :name=>"^Float"},
          {:event=>"set_return_type", :return_type=>0},
          {:event=>"type", :id=>1, :kind=>"monotype", :name=>"^Integer"},
          {:event=>"type", :id=>2, :kind=>"monotype", :name=>"^Binding"},
          {:event=>"set_arguments",
           :arguments=>
            [{:kind=>"argument", :name=>"bar", :type=>1},
             {:kind=>"argument", :name=>"baz", :type=>2}]},
          {:event=>"add_basic_block", :name=>"1"},
          {:event=>"add_instruction", :name=>"2", :basic_block=>"1", :index=>0},
          {:event=>"update_instruction",
           :name=>"2",
           :opcode=>"dup",
           :parameters=>"",
           :operands=>[{:kind=>"constant", :type=>1, :value=>"1"}],
           :type=>1},
          {:event=>"rename_instruction", :name=>"2", :new_name=>"dupped"},
          {:event=>"add_basic_block", :name=>"3"},
          {:event=>"add_instruction", :name=>"4", :basic_block=>"1", :index=>1},
          {:event=>"type", :id=>3, :kind=>"void"},
          {:event=>"update_instruction",
           :name=>"4",
           :opcode=>"branch",
           :parameters=>"",
           :operands=>[{:kind=>"basic_block", :name=>"3"}],
           :type=>3},
          {:event=>"add_instruction", :name=>"5", :basic_block=>"3", :index=>0},
          {:event=>"update_instruction",
           :name=>"5",
           :opcode=>"return_value",
           :parameters=>"",
           :operands=>[{:kind=>"instruction", :name=>"dupped"}],
           :type=>3},
          {:event=>"transform_start", :name=>"footrans"},
          {:event=>"remove_basic_block", :name=>"3"}],
          :present=>true
        }]
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
      f.name.should == 'bar;1'
      f.original_name.should == 'foo'
    end

    it 'automatically renames functions with duplicate names' do
      f1 = SSA::Function.new('foo')
      @module.add f1
      f1.name.should == 'foo'
      f1.original_name.should == 'foo'

      f2 = SSA::Function.new('foo')
      @module.add f2
      f2.name.should == 'foo;1'
      f2.original_name.should == 'foo'

      f3 = SSA::Function.new('foo;1')
      @module.add f3
      f3.name.should == 'foo;2'
      f3.original_name.should == 'foo;1'
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
