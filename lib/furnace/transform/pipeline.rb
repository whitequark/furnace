module Furnace
  module Transform
    class Pipeline
      def initialize(stages)
        @stages = stages
      end

      def run(target)
        @stages.each do |stage|
          break if stage.nil?

          target = stage.transform target
        end

        target
      end
    end
  end
end