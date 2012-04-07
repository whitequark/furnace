module Furnace::CFG
  class Node
    attr_reader   :cfg, :label

    attr_reader   :instructions, :control_flow_instruction
    alias :insns :instructions
    alias :cfi   :control_flow_instruction

    def initialize(cfg, label=nil, insns=[], cfi=nil, target_labels=[])
      @cfg, @label  = cfg, label

      @instructions = insns
      @control_flow_instruction = cfi

      @target_labels = target_labels
    end

    def target_labels
      @target_labels
    end

    def targets
      @target_labels.map do |label|
        @cfg.find_node label
      end
    end

    def source_labels
      sources.map &:label
    end

    def sources
      @cfg.source_map[self]
    end

    def ==(other)
      self.label == other.label
    end

    def inspect
      if @label || @insns.any?
        "<#{@label}:#{@insns.map(&:inspect).join ", "}>"
      else
        "<!dummy>"
      end
    end
  end
end