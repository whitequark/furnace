require 'bacon'
require 'bacon/colored_output'

class Should
  def enumerate(iterator, array)
    enum = @object.send(iterator)

    satisfy("##{iterator} should return an Enumerator, returns #{enum.class}") do
      enum.instance_of? Enumerator
    end

    values = enum.to_a
    satisfy("##{iterator} should yield #{array.inspect}, yields #{values.inspect}") do
      (values - array).empty? && (array - values).empty?
    end
  end
end

require 'simplecov'
SimpleCov.start

require 'furnace'
include Furnace

class RubyType < Type::Top
  attr_reader :ruby_type

  def initialize(ruby_type)
    @ruby_type = ruby_type
  end

  def ==(other)
    other.instance_of?(RubyType) &&
        @ruby_type == other.ruby_type
  end

  def hash
    [self.class, @ruby_type].hash
  end

  def to_s
    "^#{@ruby_type}"
  end
end

class Class
  def to_type
    RubyType.new(self)
  end
end
