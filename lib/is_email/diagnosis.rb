# frozen_string_literal: true

module IsEmail
  # Contains all types of diagnoses for address invalidity
  module Diagnosis
    require_relative "diagnosis/base"
    require_relative "diagnosis/cfws"
    require_relative "diagnosis/deprecated"
    require_relative "diagnosis/invalid"
    require_relative "diagnosis/rfc5321"
    require_relative "diagnosis/rfc5322"
    require_relative "diagnosis/valid"

    CATEGORIES = {
      "VALID" => 1,
      "DNSWARN" => 7,
      "RFC5321" => 15,
      "THRESHOLD" => 16,
      "CFWS" => 31,
      "DEPREC" => 63,
      "RFC5322" => 127,
      "ERR" => 255
    }.freeze
  end
end
