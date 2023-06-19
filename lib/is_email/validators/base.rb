# frozen_string_literal: true

module IsEmail
  module Validators
    # An abstract base class for validators
    #
    # @api private
    class Base
      # Checks whether an address is valid, optionally returning a diagnosis
      #
      # @param address [String] the address to check
      # @param diagnose [Boolean] whether to return a diagnosis or not
      # @return [Boolean, Diagnosis] when not diagnosing, true when the address
      #   is valid and false otherwise; when diagnosing, the diagnosis for the
      #   status of the address
      # :nocov:
      def email?(address, diagnose: false)
        raise NotImplementedError
      end
      # :nocov:
    end
  end
end
