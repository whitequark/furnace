module Furnace
  module Transform
    class Pipeline
      def initialize(stages)
        @stages = stages
      end

      def run(*sequence)
        @stages.each do |stage|
          break if stage.nil?

          sequence = stage.transform *sequence
        end

        sequence
      end
    end
  end
end