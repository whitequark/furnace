require 'bacon'
require 'bacon/colored_output'

class Should
  def enumerate(iterator, array)
    satisfy("##{iterator} should return an Enumerator") do
      @object.send(iterator).instance_of? Enumerator
    end

    satisfy("##{iterator} should yield #{array.inspect}") do
      (@object.send(iterator).to_a - array).empty?
    end
  end
end

require 'simplecov'
SimpleCov.start

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'furnace'
include Furnace