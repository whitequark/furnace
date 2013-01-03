module Furnace
  class SSA::Void
    def self.inspect_as_type
      'void'
    end

    def self.value
      @value ||= SSA::Constant.new(self, nil)
    end
  end
end