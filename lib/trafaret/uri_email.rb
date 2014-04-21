require 'uri'

module Trafaret
  class URI < Validator
    def prepare
      @schemes = @options.delete(:schemes) || []
    end

    def validate(data)
      uri = ::URI.parse(data)
      unless @schemes.empty? || @schemes.include?(uri.scheme)
        failure('Invalid scheme')
      else
        uri
      end
    rescue ::URI::InvalidURIError
      failure('Invalid URI')
    end

    def convert(uri)
      uri.to_s
    end
  end

  Uri = URI

  class Email < Trafaret::String
    REGEX = /\A(?<name>^[-!#$%&'*+\/=?^_`{}|~0-9A-Z]+(\.[-!#$%&'*+\/=?^_`{}|~0-9A-Z]+)*  # dot-atom
        |^"([\001-\010\013\014\016-\037!#-\[\]-\177]|\\[\001-011\013\014\016-\177])* # quoted-string
        )@(?<domain>(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?$)  # domain
        |\[(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}\]\z/xi  # literal form, ipv4 address (SMTP 4.1.3)

    def prepare
      super
      @regex = REGEX
    end
  end
end