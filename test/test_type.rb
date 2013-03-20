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

    it 'can replace itself' do
      @type.replace_type_with(@type, Type::Bottom.new).
          should == Type::Bottom.new
      @type.replace_type_with(Type::Bottom.new, nil).
          should == @type
    end

    it 'can specialize only itself' do
      @type.specialize(@type).should == {}
      -> { @type.specialize(Type::Bottom.new) }.should.raise(ArgumentError)
    end

    it 'pretty prints' do
      @type.awesome_print.should == 'top'
    end
  end

  describe Type::Bottom do
    before do
      @type = Type::Bottom.new
    end

    it 'converts to string' do
      @type.to_s.should == 'bottom'
    end

    it 'pretty prints' do
      @type.awesome_print.should == 'bottom'
    end
  end

  describe Type::Value do
    before do
      @type = Type::Value.new(1)
    end

    it 'allows to retrieve value' do
      @type.value.should == 1
    end

    it 'is a singleton' do
      @type.should.be.equal Type::Value.new(1)
    end

    it 'converts to string as \'value' do
      @type.to_s.should == %{'1}
    end

    it 'pretty prints' do
      @type.awesome_print.should == '\'1'
    end
  end

  describe Type::Variable do
    before do
      @var = Type::Variable.new
    end

    it 'allocates distinct instances' do
      Type::Variable.new.
          should.not.equal? Type::Variable.new
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

    it 'can replace itself' do
      @var.replace_type_with(@var, Type::Bottom.new).
          should == Type::Bottom.new
      @var.replace_type_with(Type::Bottom.new, nil).
          should == @var
    end

    it 'specializes' do
      @var.specialize(Type::Top.new).
          should == { @var => Type::Top.new }
    end

    it 'pretty prints' do
      @var.awesome_print.should == '~a'
    end
  end

  describe Type::Variable::Annotator do
    before do
      @annotator = Type::Variable::Annotator.new
    end

    it 'annotates variables with successive letters' do
      var1, var2 = 2.times.map { Type::Variable.new }

      @annotator.annotate(var1).should == 'a'
      @annotator.annotate(var1).should == 'a'
      @annotator.annotate(var2).should == 'b'
    end

    it 'only annotates type variables' do
      -> { @annotator.annotate(:foo) }.should.raise(ArgumentError)
    end
  end
end
