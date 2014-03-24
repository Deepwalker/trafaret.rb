module Trafaret
  class Error < Exception
    def initialize(message)
      @message = message
    end
  end
end