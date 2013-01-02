require 'bacon/colored_output'

require 'simplecov'
SimpleCov.start

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'furnace'
include Furnace