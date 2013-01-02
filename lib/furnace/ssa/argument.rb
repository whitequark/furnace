module Furnace
  class SSA::Argument < SSA::NamedValue
    attr_accessor :type

    def initialize(function, type, name)
      super(function, name)
      @type = type
    end
  end
end