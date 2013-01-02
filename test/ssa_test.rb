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

  module A
    class NestedInsn < SSA::Instruction; end
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
    TupleConcatInsn.new(basic_block, left, right)
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
      @val.pretty_print.to_s.should =~ %r{#<Furnace::SSA::Value}
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

  describe SSA::Argument do
    before do
      @val = SSA::Argument.new(@function, nil, 'foo')
    end

    it 'pretty prints' do
      SSA::Argument.new(@function, nil, 'foo').pretty_print.
          should == '<?> %foo'

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

  describe SSA::Instruction do
    it 'underscores the name' do
      DupInsn.opcode.should == 'dup'
      TupleConcatInsn.opcode.should == 'tuple_concat'
      A::NestedInsn.opcode.should == 'nested'

      A::NestedInsn.new(@basic_block).opcode.should == 'nested'
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

      zero_all = A::NestedInsn.new(@basic_block)
      zero_all.pretty_print.should == 'nested'
      zero_all.inspect_as_value.should == 'void'
    end
  end

  describe SSA::GenericInstruction do
    it 'has settable type' do
      i = GenericInsn.new(@basic_block, Integer, [])
      i.pretty_print.should == '^Integer %2 = generic'
      i.type = Binding
      i.pretty_print.should == '^Binding %2 = generic'
    end
  end

  describe SSA::BasicBlock do
    it 'receives distinct names' do
      5.times.map { SSA::BasicBlock.new(@function).name }.
          uniq.count.should == 5
    end

    it 'converts to value' do
      @basic_block.to_value.should == @basic_block
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
      @basic_block.each.should.be.instance_of Enumerator
      @basic_block.each.to_a.should == [i1]
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

=begin
    it 'can determine control transfer instruction' do
    end

    it 'can determine successors' do
    end

    it 'can determine predecessors' do
    end

    it 'can determine if it is an exit node' do
    end
=end
  end

  describe SSA::Function do
    it 'does not allow to add two basic blocks with same name' do
      bb1 = SSA::BasicBlock.new(@function, 'a')
      bb2 = SSA::BasicBlock.new(@function, 'a')
      @function.add bb1
      -> { @function.add bb2 }.should.raise ArgumentError, %r|already exists|
    end

    it 'converts to value' do
      @function.to_value.should ==
          SSA::Constant.new(SSA::Function, @function.name)

      @function.name = 'foo'
      @function.to_value.inspect_as_value.should ==
          'function "foo"'
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
      @module.each.to_a.sort_by { |a| a[0] }.should == [['bar', f2], ['foo', f1]]
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