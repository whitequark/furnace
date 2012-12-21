require_relative 'test_helper'

describe SSA::Instruction do
  class Dup < SSA::Instruction; end
  class TupleConcat < SSA::Instruction; end
  module A
    class NestedInsn < SSA::Instruction; end
  end

  it 'correctly underscores the name' do
    Dup.instruction_name.should == 'dup'
    TupleConcat.instruction_name.should == 'tuple_concat'
    A::NestedInsn.instruction_name.should == 'nested_insn'
  end
end