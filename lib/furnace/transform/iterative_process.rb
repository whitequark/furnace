module Furnace
  module Transform
    class IterativeProcess
      def initialize(stages)
        @stages = stages
      end

      def transform(*sequence)
        loop do
          changed = false

          @stages.each do |stage|
            break if stage.nil?

            if new_sequence = stage.transform(*sequence)
              changed = true
              sequence = new_sequence
            end
          end

          return sequence unless changed
        end
      end
    end
  end
end
