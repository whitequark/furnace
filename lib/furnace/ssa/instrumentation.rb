module Furnace
  module SSA
    @instrumentation = nil

    def self.instrumentation
      if block_given?
        yield @instrumentation if @instrumentation
      else
        @instrumentation
      end
    end

    def self.instrumentation=(instrumentation)
      @instrumentation = instrumentation
    end

    def self.start_instrumentation
      @instrumentation = SSA::EventStream.new
    end

    def self.dump_instrumentation(filename)
      File.open(filename, 'w') do |io|
        io.write JSON.dump(@instrumentation.data)
      end
    end

    def self.instrument(what)
      instrumentation do |i|
        i.process(what)
      end
    end
  end
end
