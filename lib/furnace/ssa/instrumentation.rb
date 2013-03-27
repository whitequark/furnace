module Furnace
  module SSA
    class << self
      attr_accessor :instrumentation
    end

    @instrumentation = nil

    def self.start_instrumentation
      @instrumentation = SSA::EventStream.new
    end

    def self.dump_instrumentation(filename)
      File.open(filename, 'w') do |io|
        io.write JSON.dump(@instrumentation.data)
      end
    end

    def self.instrument(what)
      @instrumentation.process(what) if @instrumentation
    end
  end
end
