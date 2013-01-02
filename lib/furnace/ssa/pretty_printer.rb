require 'ansi'

module Furnace
  class SSA::PrettyPrinter
    @colorize = true

    class << self
      attr_accessor :colorize
    end

    def initialize(colorize=self.class.colorize)
      @colorize   = colorize
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

    def <<(what)
      @buffer << what

      self
    end

    def text(*what)
      what = what.map(&:to_s)
      return if what.all?(&:empty?)

      ensure_space do
        self << what.join
      end
    end

    def newline
      @need_space = false

      self << "\n"
    end

    def name(what)
      text '%', what
    end

    def type(what)
      text with_ansi(:green) { Furnace::SSA.inspect_type(what) }
    end

    def keyword(what)
      text with_ansi(:bright, :white) { what.to_s }
    end

    def objects(objects, separator=",", printer=:pretty_print)
      objects.each_with_index do |object, index|
        object.send(printer, self)

        self << separator if index < objects.count - 1
      end

      self
    end

    def values(values, separator=",")
      objects(values, separator, :inspect_as_value)
    end

    protected

    def with_ansi(*colors)
      string = yield

      if @colorize
        ANSI::Code.ansi(yield, *colors)
      else
        yield
      end
    end

    def ensure_space(need_space_after=true)
      if @need_space
        self << " "
        @need_space = false
      end

      yield

      @need_space = need_space_after

      self
    end
  end
end