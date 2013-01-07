module Furnace
  class SSA::BasicBlockType < SSA::Type
    def self.instance
      @instance ||= new
    end

    def inspect
      "label"
    end
  end
end