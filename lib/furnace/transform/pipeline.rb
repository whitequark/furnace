module Furnace
  module Transform
    class Pipeline
      def initialize(stages)
        @stages = stages
      end

      def run(context)
        @stages.each do |stage|
          break if stage.nil?

          stage.run context
        end

        true
      end
    end
  end
end