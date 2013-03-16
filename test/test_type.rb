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
end
