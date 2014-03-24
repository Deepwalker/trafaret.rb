module Trafaret
  class Any < Validator
  end

  class String < Validator
    def validate(data)
      data
    end
  end

  class Integer < Validator
    def validate(data)
      data.to_i
    end
  end

  class Array < Validator
    def validate(data)
      cls = Trafaret.get_validator(@options[:validator]).new @options
      data.map do |elem|
        cls.call elem
      end
    end
  end
end