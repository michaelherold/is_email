# frozen_string_literal: true

require_relative "is_email/reference"
require_relative "is_email/diagnosis"
require_relative "is_email/validators"
require_relative "is_email/version"

# Gives an easy-to-use interface for checking the validity of email addresses
#
# Email is one of the primary ways we interact with others on the internet.
# Unfortunately, it is also one of the primary ways we abuse others on the
# internet. Because of this, we (1) ask for email addresses too often in
# transactional relationships, (2) often give incorrect email addresses, and (3)
# want to make use of email functionality to sort emails coming into our inboxes.
#
# You could say it's a fraught relationship.
#
# By doing one job, and doing it well, {IsEmail} can reduce the frustration of
# others whom we ask for their email address. No more will we be unable to use
# plus addressing to filter newsletters and track who sells our information. No
# more must we use conventional-looking email addresses to appease those who
# would fill our inboxes with messaging.
#
# {IsEmail} exists to give you an easy way to validate an email address that you
# receive to check it for typos or formats in violation of the various email
# specifications, namely:
#
# 1. [RFC1123][1], Requirements for Internet Hosts -- Application and Support
# 2. [RFC3696][2], Application Techniques for Checking and Transformation of Names
# 3. [RFC4291][3], IP Version 6 Addressing Architecture
# 4. [RFC5321][4], Simple Mail Transfer Protocol
# 5. [RFC5322][5], Internet Message Format
#
# [1]: https://datatracker.ietf.org/doc/html/rfc1123
# [2]: https://datatracker.ietf.org/doc/html/rfc3696
# [3]: https://datatracker.ietf.org/doc/html/rfc4291
# [4]: https://datatracker.ietf.org/doc/html/rfc5321
# [5]: https://datatracker.ietf.org/doc/html/rfc5322
module IsEmail
  # Validate an email address
  #
  # @api public
  #
  # @example Checking whether an email is valid
  #   IsEmail.email?("test@example.com")
  #
  # @example Investigating why an email address is invalid
  #   IsEmail.email?("test(comment)nope@example.com", diagnose: true)
  #
  # @param address [String] the email address to check
  # @param diagnose [Boolean] whether to return a diagnosis for invalidity
  #
  # @return [Boolean, Diagnosis] when not diagnosing, true when the address is
  #   valid and false otherwise; when diagnosing, the diagnosis for the status
  #   of the address
  def email?(address, diagnose: false)
    threshold = Diagnosis::CATEGORIES["THRESHOLD"]
    diagnosis = Validators::Parser.new.email?(address, diagnose: true)

    diagnose ? diagnosis : diagnosis < threshold
  end

  extend self
end
