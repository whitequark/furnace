require_relative 'test_helper'

describe Transform do
  class Context
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  class Pass
    attr_accessor :run_count

    def initialize
      @run_count = 0
    end

    def run(context)
      @run_count += 1

      if context.value > 0
        context.value -= 1
        true
      else
        false
      end
    end
  end

  before do
    @context = Context.new(3)
    @pass    = Pass.new
  end

  describe Transform::Pipeline do
    should 'run all stages' do
      pipeline = Transform::Pipeline.new([ @pass ] * 4)
      pipeline.run(@context)

      @context.value.should == 0
      @pass.run_count.should == 4
    end
  end

  describe Transform::Iterative do
    should 'run until nothing changes' do
      pipeline = Transform::Iterative.new([ @pass ] * 2)
      pipeline.run(@context)

      # [
      #   3 pass 2 -> true
      #   2 pass 1 -> true
      # ]
      # [
      #   1 pass 0 -> true
      #   0 pass 0 -> false
      # ]
      # [
      #   0 pass 0 -> false
      #   0 pass 0 -> false
      # ]

      @context.value.should == 0
      @pass.run_count.should == 6
    end

    should 'signal if any changes were made' do
      pipeline = Transform::Iterative.new([ @pass ] * 3)
      pipeline.run(@context).should == true
      pipeline.run(@context).should == false
    end
  end
end