require 'furnace'

class Furnace::Graphviz
  def initialize
    @code = "digraph {\n"
    @code << "node [labeljust=l,nojustify=true,fontname=monospace];"
    @code << "rankdir=TB;\n"

    yield self

    @code << "}"
  end

  def node(name, content, options={})
    content.gsub!("&", "&amp;")
    content.gsub!(">", "&gt;")
    content.gsub!("<", "&lt;")
    content.gsub!(/\*\*(.+?)\*\*/, '<b>\1</b>')
    content = content.lines.map { |l| %Q{<tr><td align="left">#{l}</td></tr>} }.join

    if content.empty?
      label = "<&lt;empty&gt;>"
    else
      label = "<<table border=\"0\">#{content}</table>>"
    end

    options = options.merge({
      shape: 'box',
      label: label
    })

    @code << %Q{#{name.inspect} #{graphviz_options(options)};\n}
  end

  def edge(from, to, label="", options={})
    options = options.merge({
      label: label.inspect
    })
    @code << %Q{#{from.inspect} -> #{to.inspect} #{graphviz_options(options)};\n}
  end

  def to_s
    @code
  end

  def graphviz_options(options)
    "[#{options.map { |k,v| "#{k}=#{v}" }.join(",")}]"
  end
end