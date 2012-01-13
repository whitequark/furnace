module Furnace
  class Graphviz
    def initialize
      @code = "digraph {\n"
      @code << "node [labeljust=l,nojustify=true,fontname=monospace];"
      @code << "rankdir=TB;"

      yield self

      @code << "}"
    end

    def node(name, content)
      content.gsub!("&", "&amp;")
      content.gsub!(">", "&gt;")
      content.gsub!("<", "&lt;")
      content = content.lines.map { |l| %Q{<tr><td align="left">#{l}</td></tr>} }.join

      @code << %Q{#{name.inspect} [shape=box,label=<<table border="0">#{content}</table>>];\n}
    end

    def edge(from, to, label="")
      @code << %Q{#{from.inspect} -> #{to.inspect} [label=#{label.inspect}];\n}
    end

    def to_s
      @code
    end
  end
end