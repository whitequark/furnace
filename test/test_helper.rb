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
      (values - array).empty?
    end
  end
end

require 'simplecov'
SimpleCov.start

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'furnace'
include Furnace