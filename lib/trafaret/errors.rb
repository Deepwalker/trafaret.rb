module Trafaret
  class Error < Exception
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def inspect
      "#<Trafaret::Error(#{message.inspect})>"
    end
  end
end