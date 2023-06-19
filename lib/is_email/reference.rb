# frozen_string_literal: true

module IsEmail
  # Gives contextual references to a diagnosis
  #
  # @api private
  class Reference
    DATA = {
      "local-part" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC5322 section 3.4.1"
      }.freeze,
      "local-part-maximum" => {
        link: "http://tools.ietf.org/html/rfc5321#section-4.5.3.1.1",
        citation: "RFC5321 section 4.5.3.1.1"
      }.freeze,
      "obs-local-part" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC 5322 section 3.4.1"
      }.freeze,
      "dot-atom" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC 5322 section 3.4.1"
      }.freeze,
      "quoted-string" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC 5322 section 3.4.1"
      }.freeze,
      "CFWS-near-at" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC 5322 section 3.4.1"
      }.freeze,
      "SHOULD-NOT" => {
        link: "http://tools.ietf.org/html/rfc2119",
        citation: "RFC2119 section 4"
      }.freeze,
      "atext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.2.3",
        citation: "RFC5322 section 3.2.3"
      }.freeze,
      "obs-domain" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC5322 section 3.4.1"
      }.freeze,
      "domain-RFC5322" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC5322 section 3.4.1"
      }.freeze,
      "domain-RFC5321" => {
        link: "http://tools.ietf.org/html/rfc5321#section-4.1.2",
        citation: "RFC5321 section 4.1.2"
      }.freeze,
      "label" => {
        link: "http://tools.ietf.org/html/rfc1035#section-2.3.4",
        citation: "RFC1035 section 2.3.4"
      }.freeze,
      "CRLF" => {
        link: "http://tools.ietf.org/html/rfc5234#section-2.3",
        citation: "RFC5234 section 2.3"
      }.freeze,
      "CFWS" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.2.2",
        citation: "RFC5322 section 3.2.2"
      }.freeze,
      "domain-literal" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC5322 section 3.4.1"
      }.freeze,
      "address-literal" => {
        link: "http://tools.ietf.org/html/rfc5321#section-4.1.2",
        citation: "RFC5321 section 4.1.2"
      }.freeze,
      "address-literal-IPv4" => {
        link: "http://tools.ietf.org/html/rfc5321#section-4.1.3",
        citation: "RFC5321 section 4.1.3"
      }.freeze,
      "address-literal-IPv6" => {
        link: "http://tools.ietf.org/html/rfc5321#section-4.1.3",
        citation: "RFC5321 section 4.1.3"
      }.freeze,
      "dtext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC5322 section 3.4.1"
      }.freeze,
      "obs-dtext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC5322 section 3.4.1"
      }.freeze,
      "qtext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.2.4",
        citation: "RFC5322 section 3.2.4"
      }.freeze,
      "obs-qtext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-4.1",
        citation: "RFC5322 section 4.1"
      }.freeze,
      "ctext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.2.3",
        citation: "RFC5322 section 3.2.3"
      }.freeze,
      "obs-ctext" => {
        link: "http://tools.ietf.org/html/rfc5322#section-4.1",
        citation: "RFC5322 section 4.1"
      }.freeze,
      "quoted-pair" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.2.1",
        citation: "RFC5322 section 3.2.1"
      }.freeze,
      "obs-qp" => {
        link: "http://tools.ietf.org/html/rfc5322#section-4.1",
        citation: "RFC5322 section 4.1"
      }.freeze,
      "TLD" => {
        link: "http://tools.ietf.org/html/rfc5321#section-2.3.5",
        citation: "RFC5321 section 2.3.5"
      }.freeze,
      "TLD-format" => {
        link: "http://www.rfc-editor.org/errata_search.php?eid=1353",
        citation: "John Klensin, RFC 1123 erratum 1353"
      }.freeze,
      "mailbox-maximum" => {
        link: "http://www.rfc-editor.org/errata_search.php?eid=1690",
        citation: "Dominic Sayers, RFC 3696 erratum 1690"
      }.freeze,
      "domain-maximum" => {
        link: "http://tools.ietf.org/html/rfc1035#section-4.5.3.1.2",
        citation: "RFC 5321 section 4.5.3.1.2"
      }.freeze,
      "mailbox" => {
        link: "http://tools.ietf.org/html/rfc5321#section-4.1.2",
        citation: "RFC 5321 section 4.1.2"
      }.freeze,
      "addr-spec" => {
        link: "http://tools.ietf.org/html/rfc5322#section-3.4.1",
        citation: "RFC 5322 section 3.4.1"
      }.freeze
    }.freeze

    # @param name [String]
    # @return [void]
    def initialize(name = "")
      @data = DATA.fetch(name) { {link: "", citation: ""} }
      @citation = @data[:citation]
      @link = @data[:link]
    end

    # @return [String]
    attr_reader :citation

    # @return [String]
    attr_reader :link

    private

    # @return [Hash<Symbol, String>]
    attr_reader :data
  end
end
