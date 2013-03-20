require 'ansi'

module Furnace
  class AwesomePrinter
    @colorize = true

    class << self
      attr_accessor :colorize
    end

    def initialize(colorize=self.class.colorize,
                      annotator=Type::Variable::Annotator.new)
      @colorize   = colorize
      @annotator  = annotator

      @buffer     = ""
      @need_space = false

      yield self if block_given?
    end

    def to_s
      @buffer
    end

    alias to_str to_s

    def ==(other)
      to_s == other
    end

    def =~(other)
      to_s =~ other
    end

    def append(what)
      @need_space = false
      @buffer << what.to_s

      self
    end

    def text(what)
      ensure_space { append what }
    end

    def newline
      append "\n"
    end

    def nest(what, &block)
      if what
        if what.respond_to? :awesome_print
          what.awesome_print(self)
        else
          text what.to_s
        end
      end

      self
    end

    def name(what)
      text "%#{what}"
    end

    def type(what)
      text with_ansi(:green) { what }
    end

    def type_variable(what)
      text with_ansi(:bright, :magenta) { "~#{@annotator.annotate(what)}" }
    end

    def keyword(what)
      text with_ansi(:bright, :white) { what }
    end

    def collection(left='', separator='', right='', what, &block)
      return self if what.empty?

      ensure_space do
        append left

        what.each.with_index do |element, index|
          if index > 0
            append separator
          end

          if block_given?
            yield element
          else
            nest element
          end
        end

        append right
      end
    end

    protected

    def with_ansi(*colors)
      if @colorize
        ANSI::Code.ansi(yield.to_s, *colors)
      else
        yield
      end
    end

    def ensure_space
      append " " if @need_space

      yield

      @need_space = true

      self
    end
  end
end
