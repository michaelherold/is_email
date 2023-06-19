# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/test/"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "minitest/reporters"
require "pry"
require "pry-byebug"

require "active_support"
require "active_support/core_ext/hash/conversions"

require "is_email"

Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(
    color: true
  )
]
