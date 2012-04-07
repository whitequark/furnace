module Furnace::CFG
  class Node
    attr_reader   :cfg, :label, :insns, :cfi, :target_labels
    attr_accessor :sources

    def initialize(cfg, label=nil, insns=[], cfi=nil, targets=[])
      @cfg, @label, @insns, @cfi = cfg, label, insns, cfi
      @target_labels = targets
    end

    def targets
      @target_labels.map do |label|
        @cfg.find_node label
      end
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