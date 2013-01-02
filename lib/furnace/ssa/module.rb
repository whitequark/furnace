module Furnace
  class SSA::Module
    def initialize
      @functions = {}
      @next_id   = 0
    end

    def to_a
      @functions.values
    end

    def each(&block)
      @functions.each(&block)
    end

    def include?(name)
      @functions.include? name
    end

    def [](name)
      unless @functions.include? name
        raise ArgumentError, "function #{name} is not found"
      end

      @functions[name]
    end

    def add(function, name_prefix=nil)
      if name_prefix ||
          function.name.nil? ||
          @functions.include?(function.name)

        function.name = "#{name_prefix || function.name || 'function'}$#{make_id}"
      end

      @functions[function.name] = function
    end

    def remove(name)
      @functions.delete name
    end

    protected

    def make_id
      @next_id += 1
    end
  end
end