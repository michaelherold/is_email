# frozen_string_literal: true

require "test_helper"

class TestIsEmail < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::IsEmail::VERSION
  end

  def test_email_from_module_function
    assert IsEmail.email?("test@example.com")
  end
end
