module Trafaret
  class Error < Exception
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end
end