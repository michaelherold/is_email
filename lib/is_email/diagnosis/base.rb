# frozen_string_literal: true

module IsEmail
  module Diagnosis
    # An abstract superclass for all diagnoses
    #
    # @api private
    class Base
      include Comparable

      DESCRIPTION = ""
      ERROR_CODES = {}.freeze
      MESSAGES = {}.freeze
      REFERENCES = {}.freeze

      # @param type [String]
      # @return [void]
      def initialize(type)
        @code = self.class::ERROR_CODES.fetch(type)
        @message = self.class::MESSAGES.fetch(type, "")
        @references = self.class::REFERENCES.fetch(type) { [] }.map { |ref| Reference.new(ref) }
        @type = type.to_s
      end

      # @return [Integer]
      attr_reader :code

      # @return [String]
      attr_reader :message

      # @return [Array<Reference>]
      attr_reader :references

      # @return [String]
      attr_reader :type

      # Part of the [value object semantics][1] to make diagnoses equalable
      #
      # [1]: https://thoughtbot.com/blog/value-object-semantics-in-ruby
      #
      # @param other [Object]
      # @return [Boolean]
      def ==(other)
        other.instance_of?(self.class) && (self <=> other).zero?
      end
      alias_method :eql?, :==

      # Allows sorting with Numerics and other diagnoses
      #
      # @param other [Object]
      # @return [-1, 0, 1, nil]
      def <=>(other)
        case other
        when Base
          code <=> other.code
        when Numeric
          code <=> other
        end
      end

      # Part of the [value object semantics][1] to make diagnoses equalable
      #
      # [1]: https://thoughtbot.com/blog/value-object-semantics-in-ruby
      #
      # @return [Integer]
      def hash
        [self.class, type].hash
      end

      # @return [String]
      def inspect
        "#<#{self.class.name}: #{type}>"
      end
    end
  end
end
