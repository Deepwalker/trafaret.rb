module Trafaret
  class Numeric < Validator
    UNDEFINED = 'Undefined'.freeze
    INTEGER = 'Integer'.freeze
    FLOAT = 'Float'.freeze

    def try_convert(arg)
      raise 'type method need to be implemented'
    end

    def num_class_name
      UNDEFINED
    end

    def validate(data)
      val = try_convert(data)
      return failure("Not an #{num_class_name}") unless val
      return failure('Too big') if @options[:lt] && val >= @options[:lt]
      return failure('Too big') if @options[:lte] && val > @options[:lte]
      return failure('Too small') if @options[:gt] && val <= @options[:gt]
      return failure('Too small') if @options[:gte] && val < @options[:gte]
      data
    end
  end

  class Integer < Numeric
    def try_convert(arg)
      Integer(arg) rescue nil
    end

    def num_class_name
      INTEGER
    end
  end

  class Float < Numeric
    def try_convert(arg)
      Float(arg) rescue nil
    end

    def num_class_name
      FLOAT
    end
  end
end