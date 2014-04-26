module Trafaret
  class Error < Exception
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def inspect
      "#<Trafaret::Error(#{message.inspect})>"
    end

    def dump
      case @message
      when ::Hash
        ::Hash[@message.map { |k, v| [k, v.dump] }]
      when ::Array
        @message.map &:dump
      else
        @message
      end
    end
  end
end