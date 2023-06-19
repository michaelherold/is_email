# frozen_string_literal: true

module IsEmail
  module Diagnosis
    # Indicates an address has a Comment or Folding White Space
    #
    # @api private
    class CFWS < Base
      DESCRIPTION = "Address is valid within the message but cannot be used unmodified for the envelope."

      ERROR_CODES = {
        "COMMENT" => 17,
        "FWS" => 18
      }.freeze

      MESSAGES = {
        "COMMENT" => "Address contains messages",
        "FWS" => "Address contains Folding White Space"
      }.freeze

      REFERENCES = {
        "COMMENT" => ["dot-atom"],
        "FWS" => ["local-part"]
      }.freeze
    end
  end
end
