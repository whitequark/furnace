module Furnace
  class SSA::VoidType < SSA::Type
    def inspect
      'void'
    end

    def self.instance
      @instance ||= new
    end

    def self.value
      @value ||= SSA::Constant.new(instance, nil)
    end
  end
end