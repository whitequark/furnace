module Furnace::CFG
  class Node
    attr_reader   :cfg, :label

    attr_reader   :instructions, :control_transfer_instruction
    alias :insns :instructions
    alias :cti   :control_transfer_instruction

    def initialize(cfg, label=nil, insns=[], cti=nil, target_labels=[])
      @cfg, @label  = cfg, label

      @instructions = insns
      @control_transfer_instruction = cti

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

    def exits?
      targets == [@cfg.exit]
    end

    def ==(other)
      other.is_a?(Node) && self.label == other.label
    end

    def inspect
      if @label && @instructions
        "<#{@label}:#{@instructions.join ", "}>"
      elsif @label
        "<#{@label}>"
      elsif @insns
        "<!unlabeled>"
      else
        "<!exit>"
      end
    end
  end
end