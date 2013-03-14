require 'set'

module Furnace
  module Transform
    class Iterative
      LOOP_THRESHOLD = 100

      def initialize(stages, options={})
        @stages = stages

        @debug      = options[:debug]
        @iterations = 0
      end

      def run(context)
        self_changed = false

        loop do
          changed = Set[]

          @stages.each do |stage|
            # FIXME?
            return self_changed if stage.nil?

            if stage.run(context)
              self_changed = true
              changed.add stage
            end
          end

          return self_changed if changed.empty?

          if @debug
            @iterations += 1
            if @iterations > LOOP_THRESHOLD
              raise "Transform::Iterative has detected infinite loop in: #{changed.to_a}"
            end
          end
        end
      end
    end
  end
end
