require_relative 'test_helper'

describe SSA::Instruction do
  class Dup < SSA::Instruction; end
  class TupleConcat < SSA::Instruction; end

  it 'correctly underscores the name' do
    Dup.instruction_name.should.equal 'dup'
    TupleConcat.instruction_name.should.equal 'tuple_concat'
  end
end