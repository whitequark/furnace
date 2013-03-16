require_relative 'helper'

describe Type do
  describe Type::Top do
    before do
      @type = Type::Top.new
    end

    it 'converts to type' do
      @type.to_type.should.be.equal @type
    end

    it 'is a singleton' do
      @type.should.be.equal @type
    end

    it 'should be ==, eql?, subtype_of? and have the same hash as itself' do
      @type.should == @type
      @type.should.be.eql @type
      @type.should.be.subtype_of @type
      @type.hash.should == @type.hash
    end
  end

  describe Type::Bottom do
    it 'converts to string as bottom' do
      Type::Bottom.new.to_s.should == 'bottom'
    end
  end

  describe Type::Value do
    it 'allows to retrieve value' do
      Type::Value.new(1).value.should == 1
    end

    it 'is a singleton' do
      Type::Value.new(1).
          should.be.equal Type::Value.new(1)
    end

    it 'converts to string as \'value' do
      Type::Value.new(1).to_s.should == %{'1}
    end
  end

  describe Type::Variable do
    before do
      @var = Type::Variable.new
    end

    it 'converts to type' do
      @var.to_type.should.equal? @var
    end

    it 'is a subtype of itself' do
      @var.should.be.subtype_of @var
    end

    it 'is a supertype of itself' do
      @var.should.be.supertype_of @var
    end

    it 'compares by identity' do
      @var.should == @var
      @var.should.not == Type::Variable.new
    end
  end

  describe Type::Variable::Annotator do
    it 'allocates distinct instances' do
      Type::Variable.new.
          should.not.equal? Type::Variable.new
    end

    it 'annotates variables with successive letters' do
      annotator = Type::Variable::Annotator.new
      var1, var2 = 2.times.map { Type::Variable.new }

      annotator.annotate(var1).should == 'a'
      annotator.annotate(var1).should == 'a'
      annotator.annotate(var2).should == 'b'
    end
  end
end
