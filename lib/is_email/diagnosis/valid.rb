# frozen_string_literal: true

module IsEmail
  module Diagnosis
    # Indicates an address is valid
    #
    # @api private
    class Valid < Base
      DESCRIPTION = "Address is valid."

      ERROR_CODES = {"VALID" => 1}.freeze

      MESSAGES = {
        "VALID" =>
        "Address is valid. Please note that this does not mean " \
        "the address actually exists, nor even that the domain " \
        "actually exists. This address could be issued by the " \
        "domain owner without breaking the rules of any RFCs."
      }.freeze

      # @param type [String]
      # @return [void]
      def initialize(type = "VALID")
        super
      end
    end
  end
end
