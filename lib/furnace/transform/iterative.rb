module Furnace
  module Transform
    class Iterative
      def initialize(stages)
        @stages = stages
      end

      def run(context)
        self_changed = false

        loop do
          changed = false

          @stages.each do |stage|
            return self_changed if stage.nil?

            if stage.run(context)
              self_changed = changed = true
            end
          end

          return self_changed unless changed
        end
      end
    end
  end
end
