# frozen_string_literal: true

module IsEmail
  module Validators
    # Parses an address character-by-character to determine validity
    #
    # @api private
    class Parser < Base
      # An enum-like module for containing references for key characters
      module Char
        AT = "@"
        BACKSLASH = "\\"
        DOT = "."
        DQUOTE = '"'
        OPENPARENTHESIS = "("
        CLOSEPARENTHESIS = ")"
        OPENSQBRACKET = "["
        CLOSESQBRACKET = "]"
        HYPHEN = "-"
        COLON = ":"
        DOUBLECOLON = "::"
        SP = " "
        HTAB = "\t"
        CR = "\r"
        LF = "\n"
        IPV6TAG = "IPv6:"
        # US-ASCII visible characters not valid for atext
        # (http:#tools.ietf.org/html/rfc5322#section-3.2.3)
        SPECIALS = '()<>[]:;@\\,."'
      end

      # An enum-like module for containing states for the parser state machine
      module Context
        LOCALPART = :localpart
        DOMAIN = :domain
        LITERAL = :literal
        COMMENT = :comment
        FWS = :fws
        QUOTEDSTRING = :quotedstring
        QUOTEDPAIR = :quotedpair
      end

      # Checks whether an address is valid, optionally returning a diagnosis
      #
      # @param address [String] the address to check
      # @param diagnose [Boolean] whether to return a diagnosis or not
      # @return [Boolean, Diagnosis] when not diagnosing, true when the address
      #   is valid and false otherwise; when diagnosing, the diagnosis for the
      #   status of the address
      def email?(address, diagnose: false)
        threshold = Diagnosis::CATEGORIES["VALID"]
        return_status = [Diagnosis::Valid.new]
        parse_data = {}

        # Parse the address into components, character by character
        raw_length = address.to_s.length
        context = Context::LOCALPART  # Where we are
        context_stack = [context]  # Where we've been
        context_prior = Context::LOCALPART  # Where we just came from
        token = ""  # The current character
        token_prior = ""  # The previous character
        parse_data[Context::LOCALPART] = +""  # The address' components
        parse_data[Context::DOMAIN] = +""
        atom_list = {
          Context::LOCALPART => [+""],
          Context::DOMAIN => [+""]
        }  # The address' dot-atoms
        element_count = 0
        element_len = 0
        hyphen_flag = false  # Hyphen cannot occur at the end of a subdomain
        end_or_die = false  # CFWS can only appear at the end of an element
        skip = false   # Skip flag that simulates i++
        crlf_count = nil

        raw_length.times do |i|
          if skip
            skip = false
            next
          end

          token = address[i]

          case context
          # ----------------------------------------------------------
          # Local part
          # ----------------------------------------------------------
          when Context::LOCALPART
            case token
            when Char::OPENPARENTHESIS
              if element_len == 0
                if element_count == 0
                  return_status.push(Diagnosis::CFWS.new("COMMENT"))
                else
                  return_status.push(Diagnosis::Deprecated.new("COMMENT"))
                end
              else
                return_status.push(Diagnosis::CFWS.new("COMMENT"))
                # We can't start a comment in the middle of an element, so
                # this better be the end
                end_or_die = true
              end

              context_stack.push(context)
              context = Context::COMMENT
            when Char::DOT
              if element_len == 0
                # Another dot, already? Fatal error
                if element_count == 0
                  return_status.push(Diagnosis::Invalid.new("DOT_START"))
                else
                  return_status.push(Diagnosis::Invalid.new("CONSECUTIVEDOTS"))
                end
              else
                # The entire local-part can be a quoted string for RFC 5321.
                # If it's just one atom that is quoted then it's an RFC 5322
                # obsolete form
                return_status.push(Diagnosis::Deprecated.new("LOCALPART")) if end_or_die

                # CFWS & quoted strings are OK again now we're at the
                # beginning of an element (although they are obsolete forms)
                end_or_die = false
                element_len = 0
                element_count += 1
                parse_data[Context::LOCALPART].concat(token)
                atom_list[Context::LOCALPART].push(+"")
              end
            when Char::DQUOTE
              if element_len == 0
                # The entire local-part can be a quoted string for RFC 5321.
                # If it's just one atom that is quoted then it's an RFC 5322
                # obsolete form
                if element_count == 0
                  return_status.push(Diagnosis::RFC5321.new("QUOTEDSTRING"))
                else
                  return_status.push(Diagnosis::Deprecated.new("LOCALPART"))
                end

                parse_data[Context::LOCALPART].concat(token)
                atom_list[Context::LOCALPART][element_count].concat(token)
                element_len += 1
                end_or_die = true
                context_stack.append(context)
                context = Context::QUOTEDSTRING
              else
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("EXPECTING_ATEXT"))
              end
            # Folding White Space (FWS)
            when Char::CR, Char::SP, Char::HTAB
              # Skip simulates the use of the ++ operator if the latter check
              # doesn't short-circuit
              if token == Char::CR
                skip = true

                if i + 1 == raw_length || address[i + 1] != Char::LF
                  return_status.push(Diagnosis::Invalid.new("CR_NO_LF"))
                  break
                end
              end

              if element_len == 0
                if element_count == 0
                  return_status.push(Diagnosis::CFWS.new("FWS"))
                else
                  return_status.push(Diagnosis::Deprecated.new("FWS"))
                end
              else
                # We can't start FWS in the middle of an element, so this
                # better be the end
                end_or_die = true
              end

              context_stack.push(context)
              context = Context::FWS
              token_prior = token
            # @
            when Char::AT
              # At this point we should have a valid local-part
              if context_stack.length != 1
                if diagnose
                  return Diagnosis::Invalid.new("BAD_PARSE")
                else
                  return false
                end
              end

              if parse_data[Context::LOCALPART] == ""
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("NOLOCALPART"))
              elsif element_len == 0
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("DOT_END"))
              # http://tools.ietf.org/html/rfc5321#section-4.5.3.1.1
              #   The maximum total length of a user name or other local-part
              #   is 64 octets.
              elsif parse_data[Context::LOCALPART].length > 64
                return_status.push(Diagnosis::RFC5322.new("LOCAL_TOOLONG"))
              # http://tools.ietf.org/html/rfc5322#section-3.4.1
              #   Comments and folding white space SHOULD NOT be used around
              #   the "@" in the addr-spec.
              #
              # http://tools.ietf.org/html/rfc2119
              # 4. SHOULD NOT   This phrase, or the phrase "NOT RECOMMENDED"
              #    mean that there may exist valid reasons in particular
              #    circumstances when the particular behavior is acceptable or
              #    even useful, but the full implications should be understood
              #    and the case carefully weighed before implementing any
              #    behavior described with this label.
              elsif context_prior == Context::COMMENT || context_prior == Context::FWS
                return_status.push(Diagnosis::Deprecated.new("CFWS_NEAR_AT"))
              end

              # Clear everything down for the domain parsing
              context = Context::DOMAIN
              context_stack = []
              element_count = 0
              element_len = 0
              # CFWS can only appear at the end of the element
              end_or_die = false
            # atext
            else
              if end_or_die
                # http://tools.ietf.org/html/rfc5322#section-3.2.3
                #    atext  =  ALPHA / DIGIT /  ; Printable US-ASCII
                #              "!" / "#" /      ; characters not
                #              "$" / "%" /      ; including specials.
                #              "&" / "'" /      ; Used for atoms.
                #              "*" / "+" /
                #              "-" / "/" /
                #              "=" / "?" /
                #              "^" / "_" /
                #              "`" / "{" /
                #              "|" / "}" /
                #              "~"
                case context_prior
                when Context::COMMENT, Context::FWS
                  return_status.push(Diagnosis::Invalid.new("ATEXT_AFTER_CFWS"))
                when Context::QUOTEDSTRING
                  return_status.push(Diagnosis::Invalid.new("ATEXT_AFTER_QS"))
                else
                  if diagnose
                    return Diagnosis::Invalid.new("BAD_PARSE")
                  else
                    return false
                  end
                end
              # We have encountered atext where it is no longer valid
              else
                context_prior = context
                o = token.ord

                if o < 33 || o > 126 || o == 10 || Char::SPECIALS.include?(token)
                  return_status.push(Diagnosis::Invalid.new("EXPECTING_ATEXT"))
                end

                parse_data[Context::LOCALPART].concat(token)
                atom_list[Context::LOCALPART][element_count].concat(token)
                element_len += 1
              end
            end
          # ----------------------------------------------------------
          # Domain
          # ----------------------------------------------------------
          when Context::DOMAIN
            # http://tools.ietf.org/html/rfc5322#section-3.4.1
            #   domain         = dot-atom / domain-literal / obs-domain
            #
            #   dot-atom       = [CFWS] dot-atom-text [CFWS]
            #
            #   dot-atom-text  = 1*atext *("." 1*atext)
            #
            #   domain-literal = [CFWS]
            #                    "[" *([FWS] dtext) [FWS] "]"
            #                    [CFWS]
            #
            #   dtext          = %d33-90 /     ; Printable US-ASCII
            #                    %d94-126 /    ; characters not
            #                    obs-dtext     ; including [, ], or \
            #
            #   obs-domain     = atom *("." atom)
            #
            #   atom           = [CFWS] 1*atext [CFWS]
            #
            #
            # http://tools.ietf.org/html/rfc5321#section-4.1.2
            #   Mailbox       = Local-part
            #                   "@"
            #                   ( Domain / address-literal )
            #
            #   Domain        = sub-domain *("." sub-domain)
            #
            #   address-literal  = "[" ( IPv4-address-literal /
            #                            IPv6-address-literal /
            #                            General-address-literal ) "]"
            #                    ; See Section 4.1.3
            #
            # http://tools.ietf.org/html/rfc5322#section-3.4.1
            #      Note: A liberal syntax for the domain portion of
            #      addr-spec is given here. However, the domain portion
            #      contains addressing information specified by and
            #      used in other protocols (e.g., RFC 1034, RFC 1035,
            #      RFC 1123, RFC5321). It is therefore incumbent upon
            #      implementations to conform to the syntax of
            #      addresse for the context in which they are used.
            # is_email() author's note: it's not clear how to interpret
            # this in the context of a general address address
            # validator. The conclusion I have reached is this:
            # "addressing information" must comply with RFC 5321 (and
            # in turn RFC 1035), anything that is "semantically
            # invisible" must comply only with RFC 5322.

            case token
            # Comment
            when Char::OPENPARENTHESIS
              if element_len == 0
                # Comments at the start of the domain are
                # deprecated in the text
                # Comments at the start of a subdomain are
                # obs-domain
                # (http://tools.ietf.org/html/rfc5322#section-3.4.1)
                if element_count == 0
                  return_status.push(Diagnosis::Deprecated.new("CFWS_NEAR_AT"))
                else
                  return_status.push(Diagnosis::Deprecated.new("COMMENT"))
                end
              else
                return_status.push(Diagnosis::CFWS.new("COMMENT"))
                # We can't start a coment in the middle of an element, so this
                # better be the end
                end_or_die = true
              end

              context_stack.push(context)
              context = Context::COMMENT
            # Next dot-atom element
            when Char::DOT
              if element_len == 0
                # Another dot, already? Fatal error
                if element_count == 0
                  return_status.push(Diagnosis::Invalid.new("DOT_START"))
                else
                  return_status.push(Diagnosis::Invalid.new("CONSECUTIVEDOTS"))
                end
              elsif hyphen_flag
                # Previous subdomain ended in a hyphen. Fatal error
                return_status.push(Diagnosis::Invalid.new("DOMAINHYPHENEND"))
              else
                # Nowhere in RFC 5321 does it say explicitly that
                # the domain part of a Mailbox must be a valid
                # domain according to the DNS standards set out in
                # RFC 1035, but this *is* implied in several
                # places. For instance, wherever the idea of host
                # routing is discussed the RFC says that the domain
                # must be looked up in the DNS. This would be
                # nonsense unless the domain was designed to be a
                # valid DNS domain. Hence we must conclude that the
                # RFC 1035 restriction on label length also applies
                # to RFC 5321 domains.
                #
                # http://tools.ietf.org/html/rfc1035#section-2.3.4
                # labels         63 octets or less
                if element_len > 63
                  return_status.append(Diagnosis::RFC5322.new("LABEL_TOOLONG"))
                end

                # CFWS is OK again now we're at the beginning of an
                # element (although it may be obsolete CFWS)
                end_or_die = false
                element_len = 0
                element_count += 1
                atom_list[Context::DOMAIN].push(+"")
                parse_data[Context::DOMAIN].concat(token)
              end
            # Domain literal
            when Char::OPENSQBRACKET
              if parse_data[Context::DOMAIN] == ""
                # Domain literal must be the only component
                end_or_die = true
                element_len += 1
                context_stack.push(context)
                context = Context::LITERAL
                parse_data[Context::DOMAIN].concat(token)
                atom_list[Context::DOMAIN][element_count].concat(token)
                parse_data["literal"] = +""
              else
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("EXPECTING_ATEXT"))
              end
            # Folding White Space (FWS)
            when Char::CR, Char::SP, Char::HTAB
              # Skip simulates the use of the ++ operator if the latter check
              # doesn't short-circuit
              if token == Char::CR
                skip = true

                if i + 1 == raw_length || address[i + 1] != Char::LF
                  return_status.push(Diagnosis::Invalid.new("CR_NO_LF"))
                  break
                end
              end

              if element_len == 0
                if element_count == 0
                  return_status.push(Diagnosis::Deprecated.new("CFWS_NEAR_AT"))
                else
                  return_status.push(Diagnosis::Deprecated.new("FWS"))
                end
              else
                return_status.push(Diagnosis::CFWS.new("FWS"))
                # We can't start FWS in the mdidle of an element, so this better be the end
                end_or_die = true
              end

              context_stack.push(context)
              context = Context::FWS
              token_prior = token
            # atext
            else
              # RFC 5322 allows any atext...
              # http://tools.ietf.org/html/rfc5322#section-3.2.3
              #    atext  =  ALPHA / DIGIT / ; Printable US-ASCII
              #              "!" / "#" /     ; characters not
              #              "$" / "%" /     ; including specials.
              #              "&" / "'" /     ; Used for atoms.
              #              "*" / "+" /
              #              "-" / "/" /
              #              "=" / "?" /
              #              "^" / "_" /
              #              "`" / "{" /
              #              "|" / "}" /
              #              "~"

              # But RFC 5321 only allows letter-digit-hyphen to comply with
              # DNS rules (RFCs 1034 & 1123)
              # http://tools.ietf.org/html/rfc5321#section-4.1.2
              #   sub-domain     = Let-dig [Ldh-str]
              #
              #   Let-dig        = ALPHA / DIGIT
              #
              #   Ldh-str        = *( ALPHA / DIGIT / "-" ) Let-dig
              if end_or_die
                case context_prior
                # We have encountered atext where it is no longer valid
                when Context::COMMENT, Context::FWS
                  return_status.push(Diagnosis::Invalid.new("ATEXT_AFTER_CFWS"))
                when Context::LITERAL
                  return_status.push(Diagnosis::Invalid.new("ATEXT_AFTER_DOMLIT"))
                else
                  if diagnose
                    return Diagnosis::Invalid.new("BAD_PARSE")
                  else
                    return false
                  end
                end
              end

              o = token.ord
              # Assume this token isn't a hyphen unless we discover it is
              hyphen_flag = false

              if o < 33 || o > 126 || Char::SPECIALS.include?(token)
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("EXPECTING_ATEXT"))
              elsif token == Char::HYPHEN
                if element_len == 0
                  # Hyphens can't be at the beginning of a subdomain
                  # Fatal error
                  return_status.push(Diagnosis::Invalid.new("DOMAINHYPHENSTART"))
                end

                hyphen_flag = true
              elsif !((48...58).cover?(o) || (65...91).cover?(o) || (97...123).cover?(o))
                # Not an RFC 5321 subdomain, but still OK by RFC 5322
                return_status.push(Diagnosis::RFC5322.new("DOMAIN"))
              end

              parse_data[Context::DOMAIN].concat(token)
              atom_list[Context::DOMAIN][element_count].concat(token)
              element_len += 1
            end
          # ----------------------------------------------------------
          # Domain literal
          # ----------------------------------------------------------
          when Context::LITERAL
            # http://tools.ietf.org/html/rfc5322#section-3.4.1
            #   domain-literal = [CFWS]
            #                    "[" *([FWS] dtext) [FWS] "]"
            #                    [CFWS]
            #
            #   dtext          = %d33-90 /     ; Printable US-ASCII
            #                    %d94-126 /    ; characters not
            #                    obs-dtext     ; including [, ], or \
            #
            #   obs-dtext      = obs-NO-WS-CTL / quoted-pair

            case token
            # End of domain literal
            when Char::CLOSESQBRACKET
              if return_status.max < Diagnosis::CATEGORIES["DEPREC"]
                # Could be a valid RFC 5321 address literal, so
                # let's check
                #
                # http://tools.ietf.org/html/rfc5321#section-4.1.2
                #   address-literal  = "[" ( IPv4-address-literal /
                #                    IPv6-address-literal /
                #                    General-address-literal ) "]"
                #                    ; See Section 4.1.3
                #
                # http://tools.ietf.org/html/rfc5321#section-4.1.3
                #   IPv4-address-literal  = Snum 3("."  Snum)
                #
                #   IPv6-address-literal  = "IPv6:" IPv6-addr
                #
                #   General-address-literal  = Standardized-tag ":"
                #                              1*dcontent
                #
                #   Standardized-tag  = Ldh-str
                #                     ; Standardized-tag MUST be
                #                     ; specified in a
                #                     ; Standards-Track RFC and
                #                     ; registered with IANA
                #
                #   dcontent     = %d33-90 / ; Printable US-ASCII
                #                  %d94-126  ; excl. "[", "\", "]"
                #
                #   Snum         = 1*3DIGIT
                #                ; representing a decimal integer
                #                ; value in the range 0-255
                #
                #   IPv6-addr    = IPv6-full / IPv6-comp /
                #                  IPv6v4-full / IPv6v4-comp
                #
                #   IPv6-hex     = 1*4HEXDIG
                #
                #   IPv6-full    = IPv6-hex 7(":" IPv6-hex)
                #
                #   IPv6-comp    = [IPv6-hex *5(":" IPv6-hex)]
                #                  "::"
                #                  [IPv6-hex *5(":" IPv6-hex)]
                #                ; The "::" represents at least 2
                #                ; 16-bit groups of zeros. No more
                #                ; than 6 groups in addition to
                #                ; the "::" may be present.
                #
                #   IPv6v4-full  = IPv6-hex 5(":" IPv6-hex) ":"
                #                  IPv4-address-literal
                #
                #   IPv6v4-comp  = [IPv6-hex *3(":" IPv6-hex)]
                #                  "::"
                #                  [IPv6-hex *3(":" IPv6-hex) ":"]
                #                  IPv4-address-literal
                #                ; The "::" represents at least 2
                #                ; 16-bit groups of zeros. No more
                #                ; than 4 groups in addition to
                #                ; the "::" and
                #                ; IPv4-address-literal may be
                #                ; present.
                max_groups = 8
                index = false
                address_literal = parse_data["literal"]

                # Extract IPv4 part from the end of the address-literal (if
                # there is one)
                match_ip = address_literal.match(%r{
                  \b
                  (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}
                  (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
                  $
                }x)
                if match_ip
                  index = address_literal.rindex(match_ip[0])

                  if index != 0
                    # Convert the IPv4 part to IPv6 format for further testing
                    address_literal = address_literal[0, index] + "0:0"
                  end
                end

                if index == 0
                  # Nothing there except a valid IPv4 address
                  return_status.push(Diagnosis::RFC5321.new("ADDRESSLITERAL"))
                elsif !address_literal.start_with?(Char::IPV6TAG)
                  return_status.push(Diagnosis::RFC5322.new("DOMAINLITERAL"))
                else
                  ipv6 = address_literal[5..]
                  # Revision 2.7: Daniel Marschall's new IPv6 testing strategy
                  match_ip = ipv6.split(Char::COLON)
                  grp_count = match_ip.length
                  index = ipv6.index(Char::DOUBLECOLON)

                  if index.nil?
                    # We need exactly the right number of groups
                    if grp_count != max_groups
                      return_status.push(Diagnosis::RFC5322.new("IPV6_GRPCOUNT"))
                    end
                  elsif index != ipv6.rindex(Char::DOUBLECOLON)
                    return_status.push(Diagnosis::RFC5322.new("IPV6_2X2XCOLON"))
                  else
                    if index == 0 || index == ipv6.length - 2
                      # RFC 4921 allows a :: at the start of end of an
                      # address with 7 other groups in addition
                      max_groups += 1
                    end

                    if grp_count > max_groups
                      return_status.push(Diagnosis::RFC5322.new("IPV6_MAXGRPS"))
                    elsif grp_count == max_groups
                      # Eliding a single "::"
                      return_status.push(Diagnosis::RFC5321.new("IPV6DEPRECATED"))
                    end
                  end

                  # Revision 2.7: Daniel Marschall's new IPv6 testing strategy
                  if ipv6[0] == Char::COLON && ipv6[1] != Char::COLON
                    # Address starts with a single colon
                    return_status.push(Diagnosis::RFC5322.new("IPV6_COLONSTRT"))
                  elsif ipv6[-1] == Char::COLON && ipv6[-2] != Char::COLON
                    # Address ends with a single colon
                    return_status.push(Diagnosis::RFC5322.new("IPV6_COLONEND"))
                  elsif match_ip.any? { |segment| segment !~ /\A[0-9a-f]{0,4}\z/i }
                    # Check for unmatched characters
                    return_status.push(Diagnosis::RFC5322.new("IPV6_BADCHAR"))
                  else
                    return_status.push(Diagnosis::RFC5321.new("ADDRESSLITERAL"))
                  end
                end
              else
                return_status.push(Diagnosis::RFC5322.new("DOMAINLITERAL"))
              end

              parse_data[Context::DOMAIN].concat(token)
              atom_list[Context::DOMAIN][element_count].concat(token)
              element_len += 1
              context_prior = context
              context = context_stack.pop
            when Char::BACKSLASH
              return_status.push(Diagnosis::RFC5322.new("DOMLIT_OBSDTEXT"))
              context_stack.push(context)
              context = Context::QUOTEDPAIR
            # Folding White Space (FWS)
            when Char::CR, Char::SP, Char::HTAB
              # Skip simulates the use of the ++ operator if the latter check
              # doesn't short-circuit
              if token == Char::CR
                skip = true

                if i + 1 == raw_length || address[i + 1] != Char::LF
                  return_status.push(Diagnosis::Invalid.new("CR_NO_LF"))
                  break
                end
              end

              return_status.push(Diagnosis::CFWS.new("FWS"))
              context_stack.push(context)
              context = Context::FWS
              token_prior = token
            # dtext
            else
              # http://tools.ietf.org/html/rfc5322#section-3.4.1
              #   dtext         = %d33-90 /   ; Printable US-ASCII
              #                   %d94-126 /  ; characters not
              #                   obs-dtext   ; including [, ], or \
              #
              #   obs-dtext     = obs-NO-WS-CTL / quoted-pair
              #
              #   obs-NO-WS-CTL = %d1-8 /     ; US-ASCII control
              #                   %d11 /      ; characters that do
              #                   %d12 /      ; not include the
              #                   %d14-31 /   ; carriage return, line
              #                   %d127       ; feed, and white space
              #                               ; characters
              o = token.ord

              # CR, LF, SP & HTAB have already been parsed above
              if o > 127 || o == 0 || token == Char::OPENSQBRACKET
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("EXPECTING_DTEXT"))
                break
              elsif o < 33 || o == 127
                return_status.push(Diagnosis::RFC5322.new("DOMLIT_OBSDTEXT"))
              end

              parse_data["literal"].concat(token)
              parse_data[Context::DOMAIN].concat(token)
              atom_list[Context::DOMAIN][element_count].concat(token)
              element_len += 1
            end
          # ----------------------------------------------------------
          # Quoted string
          # ----------------------------------------------------------
          when Context::QUOTEDSTRING
            # http://tools.ietf.org/html/rfc5322#section-3.2.4
            #   quoted-string   =  [CFWS]
            #                      DQUOTE *([FWS] qcontent) [FWS] DQUOTE
            #                      [CFWS]
            #
            #   qcontent        =  qtext / quoted-pair

            case token
            # Quoted pair
            when Char::BACKSLASH
              context_stack.push(context)
              context = Context::QUOTEDPAIR
            # Folding White Space (FWS)
            # Inside a quoted string, spaces are allowed as regular
            # characters. It's only FWS if we include HTAB or CRLF
            when Char::CR, Char::HTAB
              # Skip simulates the use of the ++ operator if the latter check
              # doesn't short-circuit
              if token == Char::CR
                skip = true

                if i + 1 == raw_length || address[i + 1] != Char::LF
                  return_status.push(Diagnosis::Invalid.new("CR_NO_LF"))
                  break
                end
              end

              # http://tools.ietf.org/html/rfc5322#section-3.2.2
              #   Runs of FWS, comment, or CFWS that occur between lexical
              #   tokens in a structured header field are semantically
              #   interpreted as a single space character.

              # http://tools.ietf.org/html/rfc5322#section-3.2.4
              #   the CRLF in any FWS/CFWS that appears within the quoted
              #   string [is] semantically "invisible" and therefore not part
              #   of the quoted-string
              parse_data[Context::LOCALPART].concat(Char::SP)
              atom_list[Context::LOCALPART][element_count].concat(Char::SP)
              element_len += 1

              return_status.push(Diagnosis::CFWS.new("FWS"))
              context_stack.push(context)
              context = Context::FWS
              token_prior = token
            # End of quoted string
            when Char::DQUOTE
              parse_data[Context::LOCALPART].concat(token)
              atom_list[Context::LOCALPART][element_count].concat(token)
              element_len += 1
              context_prior = context
              context = context_stack.pop
            # qtext
            else
              # http://tools.ietf.org/html/rfc5322#section-3.2.4
              #   qtext          =  %d33 /      ; Printable US-ASCII
              #                     %d35-91 /   ; characters not
              #                     %d93-126 /  ; including "\" or
              #                     obs-qtext   ; the quote
              #                                 ; character
              #
              #   obs-qtext      =  obs-NO-WS-CTL
              #
              #   obs-NO-WS-CTL  =  %d1-8 /     ; US-ASCII control
              #                     %d11 /      ; characters that do
              #                     %d12 /      ; not include the CR,
              #                     %d14-31 /   ; LF, and white space
              #                     %d127       ; characters
              o = token.ord

              if o > 127 || o == 0 || o == 10
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("EXPECTING_QTEXT"))
              elsif o < 32 || o == 127
                return_status.push(Diagnosis::Deprecated.new("QTEXT"))
              end

              parse_data[Context::LOCALPART].concat(token)
              atom_list[Context::LOCALPART][element_count].concat(token)
              element_len += 1
            end
          # ----------------------------------------------------------
          # Quoted pair
          # ----------------------------------------------------------
          when Context::QUOTEDPAIR
            # http://tools.ietf.org/html/rfc5322#section-3.2.1
            #   quoted-pair     =   ("\" (VCHAR / WSP)) / obs-qp
            #
            #   VCHAR           =  %d33-126    ; visible (printing)
            #                                  ;  characters
            #
            #   WSP             =  SP / HTAB   ; white space
            #
            #   obs-qp          =   "\" (%d0 / obs-NO-WS-CTL / LF / CR)
            #
            #   obs-NO-WS-CTL   =   %d1-8 /    ; US-ASCII control
            #                       %d11 /     ; characters that do not
            #                       %d12 /     ; include the carriage
            #                       %d14-31 /  ; return, line feed, and
            #                       %d127      ; white space characters
            #
            # i.e. obs-qp       =  "\" (%d0-8, %d10-31 / %d127)
            o = token.ord

            if o > 127
              # Fatal error
              return_status.push(Diagnosis::Invalid.new("EXPECTING_QPAIR"))
            elsif (o < 31 && o != 9) || o == 127
              # SP & HTAB are allowed
              return_status.push(Diagnosis::Deprecated.new("QP"))
            end

            # At this point we know where this qpair occurred so we could
            # check to see if the character actually needed to be quoted at
            # all.
            # http://tools.ietf.org/html/rfc5321#section-4.1.2
            #   the sending system SHOULD transmit the
            #   form that uses the minimum quoting possible.
            context_prior = context
            context = context_stack.pop  # End of qpair
            token = Char::BACKSLASH + token

            case context
            when Context::COMMENT
              # no-op
            when Context::QUOTEDSTRING
              parse_data[Context::LOCALPART].concat(token)
              atom_list[Context::LOCALPART][element_count].concat(token)
              # The maximum sizes specified by RFC 5321 are octet counts, so
              # we must include the backslash
              element_len += 2
            when Context::LITERAL
              parse_data[Context::DOMAIN].concat(token)
              atom_list[Context::DOMAIN][element_count].concat(token)
              # The maximum sizes specified by RFC 5321 are octet counts, so
              # we must include the backslash
              element_len += 2
            else
              if diagnose
                return Diagnosis::Invalid.new("BAD_PARSE")
              else
                return false
              end
            end
          # ----------------------------------------------------------
          # Comment
          # ----------------------------------------------------------
          when Context::COMMENT
            # http://tools.ietf.org/html/rfc5322#section-3.2.2
            #   comment         =   "(" *([FWS] ccontent) [FWS] ")"
            #
            #   ccontent        =   ctext / quoted-pair / comment

            case token
            # Nested comment
            when Char::OPENPARENTHESIS
              # Nested comments are OK
              context_stack.push(context)
              context = Context::COMMENT
            # End of comment
            when Char::CLOSEPARENTHESIS
              context_prior = context
              context = context_stack.pop
            # Quoted pair
            when Char::BACKSLASH
              context_stack.push(context)
              context = Context::QUOTEDPAIR
            # Folding White Space (FWS)
            when Char::CR, Char::SP, Char::HTAB
              # Skip simulates the use of the ++ operator if the latter check
              # doesn't short-circuit
              if token == Char::CR
                skip = true

                if i + 1 == raw_length || address[i + 1] != Char::LF
                  return_status.push(Diagnosis::Invalid.new("CR_NO_LF"))
                  break
                end
              end

              return_status.push(Diagnosis::CFWS.new("FWS"))
              context_stack.push(context)
              context = Context::FWS
              token_prior = token
            # ctext
            else
              # http://tools.ietf.org/html/rfc5322#section-3.2.3
              #   ctext           =   %d33-39 /   ; Printable US-
              #                       %d42-91 /   ; ASCII characters
              #                       %d93-126 /  ; not including
              #                       obs-ctext   ; "(", ")", or "\"
              #
              #   obs-ctext       =   obs-NO-WS-CTL
              #
              #   obs-NO-WS-CTL   =   %d1-8 /      ; US-ASCII control
              #                       %d11 /       ; characters that
              #                       %d12 /       ; do not include
              #                       %d14-31 /    ; the CR, LF, and
              #                                    ; white space
              #                                    ; characters
              o = token.ord

              if o > 127 || o == 0 || o == 10
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("EXPECTING_CTEXT"))
              elsif o < 32 || o == 127
                return_status.push(Diagnosis::Deprecated.new("CTEXT"))
              end
            end
          # ----------------------------------------------------------
          # Folding White Space (FWS)
          # ----------------------------------------------------------
          when Context::FWS
            # http://tools.ietf.org/html/rfc5322#section-3.2.2
            #   FWS             =   ([*WSP CRLF] 1*WSP) /  obs-FWS
            #                       ; Folding white space
            #
            # But note the erratum:
            # http://www.rfc-editor.org/errata_search.php?rfc=5322&eid=1908
            #   In the obsolete syntax, any amount of folding white
            #   space MAY be inserted where the obs-FWS rule is
            #   allowed. This creates the possibility of having two
            #   consecutive "folds" in a line, and therefore the
            #   possibility that a line which makes up a folded header
            #   field could be composed entirely of white space.
            #
            #   obs-FWS         =   1*([CRLF] WSP)
            if token_prior == Char::CR
              if token == Char::CR
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("FWS_CRLF_X2"))
                break
              end

              if crlf_count
                crlf_count += 1
                if crlf_count > 1
                  return_status.push(Diagnosis::Deprecated.new("FWS"))
                end
              else
                crlf_count = 1
              end
            end

            case token
            # Skip simulates the use of the ++ operator if the latter check
            # doesn't short-circuit
            when Char::CR
              skip = true

              if i + 1 == raw_length || address[i + 1] != Char::LF
                return_status.push(Diagnosis::Invalid.new("CR_NO_LF"))
                break
              end
            when Char::SP, Char::HTAB
              # no-op
            else
              if token_prior == Char::CR
                # Fatal error
                return_status.push(Diagnosis::Invalid.new("FWS_CRLF_END"))
                break
              end

              crlf_count = nil

              context_prior = context
              # End of FWS
              context = context_stack.pop

              # Look at this token again in the parent context
              redo
            end

            token_prior = token
          # ----------------------------------------------------------
          # A context we aren't expecting
          # ----------------------------------------------------------
          else
            if diagnose
              return Diagnosis::Invalid.new("BAD_PARSE")
            else
              return false
            end
          end

          # No point in going on if we've got a fatal error
          break if return_status.max > Diagnosis::CATEGORIES["RFC5322"]
        end # end loop

        # Some simple final tests
        if return_status.max < Diagnosis::CATEGORIES["RFC5322"]
          if context == Context::QUOTEDSTRING
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("UNCLOSEDQUOTEDSTR"))
          elsif context == Context::QUOTEDPAIR
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("BACKSLASHEND"))
          elsif context == Context::COMMENT
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("UNCLOSEDCOMMENT"))
          elsif context == Context::LITERAL
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("UNCLOSEDDOMLIT"))
          elsif token == Char::CR
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("FWS_CRLF_END"))
          elsif parse_data[Context::DOMAIN] == ""
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("NODOMAIN"))
          elsif element_len == 0
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("DOT_END"))
          elsif hyphen_flag
            # Fatal error
            return_status.push(Diagnosis::Invalid.new("DOMAINHYPHENEND"))
          # http://tools.ietf.org/html/rfc5321#section-4.5.3.1.2
          # The maximum total length of a domain name or number is 255 octets
          elsif parse_data[Context::DOMAIN].length > 255
            return_status.push(Diagnosis::RFC5322.new("DOMAIN_TOOLONG"))
          # http://tools.ietf.org/html/rfc5321#section-4.1.2
          #   Forward-path   = Path
          #
          #   Path           = "<" [ A-d-l ":" ] Mailbox ">"
          #
          # http://tools.ietf.org/html/rfc5321#section-4.5.3.1.3
          #   The maximum total length of a reverse-path or forward-path is
          #   256 octets (including the punctuation and element separators).
          #
          # Thus, even without (obsolete) routing information, the Mailbox
          # can only be 254 characters long. This is confirmed by this
          # verified erratum to RFC 3696:
          #
          # http://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690
          #   However, there is a restriction in RFC 2821 on the length of an
          #   address in MAIL and RCPT commands of 254 characters.  Since
          #   addresses that do not fit in those fields are not normally
          #   useful, the upper limit on address lengths should normally be
          #   considered to be 254.
          elsif (parse_data[Context::LOCALPART] + Char::AT + parse_data[Context::DOMAIN]).length > 254
            return_status.push(Diagnosis::RFC5322.new("TOOLONG"))
          # http://tools.ietf.org/html/rfc1035#section-2.3.4
          # labels           63 octets or less
          elsif element_len > 63
            return_status.push(Diagnosis::RFC5322.new("LABEL_TOOLONG"))
          end
        end

        return_status.uniq!
        final_status = return_status.max

        # Remove redundant Valid diagnosis
        return_status.shift if return_status.length != 1

        parse_data["status"] = return_status

        final_status = Diagnosis::Valid.new if final_status < threshold

        if diagnose
          final_status
        else
          final_status < Diagnosis::CATEGORIES["THRESHOLD"]
        end
      end # end def
    end
  end
end
