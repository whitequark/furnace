module Furnace
  class SSA::FunctionType < SSA::Type
    def self.instance
      @instance ||= new
    end

    def inspect
      "function"
    end
  end
end