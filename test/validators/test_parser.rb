# frozen_string_literal: true

require "test_helper"

module IsEmail
  module Validators
    class TestParser < Minitest::Test
      WHITESPACE_RANGE = (9216..9229)
      THRESHOLD = Diagnosis::CATEGORIES["THRESHOLD"]

      def self.normalize_test_hacks(address)
        return unless address

        address.each_char.map { |char|
          next char unless WHITESPACE_RANGE.cover?(char.ord)

          (char.ord - 9216).chr
        }.join
      end

      File
        .expand_path("../data/tests.xml", __dir__)
        .then { |path| File.read(path) }
        .then { |xml| Hash.from_xml(xml) }
        .dig("tests", "test")
        .each do |definition|
          address = normalize_test_hacks(definition["address"])
          diagnosis = definition["diagnosis"]

          define_method("test_#{definition["id"]}_without_diagnosis") do
            validator = Parser.new

            result = validator.email?(address)
            expected = create_diagnosis(diagnosis) < THRESHOLD

            assert_equal(expected, result)
          end

          define_method("test_#{definition["id"]}_with_diagnosis") do
            validator = Parser.new

            result = validator.email?(address, diagnose: true)
            expected = create_diagnosis(diagnosis)

            assert_equal(expected, result)
          end
        end

      private

      def create_diagnosis(tag)
        _, klass, *type = tag.split("_")
        diagnosis_class = diagnosis_class_from(klass)
        type = type.join("_")
        type = "VALID" if type == "" && diagnosis_class == Diagnosis::Valid

        diagnosis_class.new(type)
      end

      def diagnosis_class_from(tag)
        case tag
        when "ERR" then Diagnosis::Invalid
        when "VALID" then Diagnosis::Valid
        when "RFC5321" then Diagnosis::RFC5321
        when "RFC5322" then Diagnosis::RFC5322
        when "CFWS" then Diagnosis::CFWS
        when "DEPREC" then Diagnosis::Deprecated
        else raise ArgumentError, "unknown tag type: #{tag}"
        end
      end
    end
  end
end
