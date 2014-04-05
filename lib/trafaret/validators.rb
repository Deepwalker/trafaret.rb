module Trafaret
  class Any < Validator
  end

  class ADT < Validator
    attr_reader :validators

    def initialize(*args)
      args = args.first if args.first.is_a? ::Array
      @validators = args.map { |v| Trafaret.get_instantiated_validator(v) }
    end
  end

  class Or < ADT
    def validate(data)
      errors = []
      @validators.each do |v|
        res = v.call(data)
        if res.is_a? Trafaret::Error
          errors << res
        else
          return res
        end
      end
      return failure errors
    end

    def |(other)
      Trafaret::Or.new(*validators, other)
    end
  end

  class Chain < ADT
    def validate(data)
      @validators.each do |v|
        data = v.call(data)
        return data if data.is_a? Trafaret::Error
      end
      data
    end

    def &(other)
      Trafaret::Chain.new(*validators, other)
    end
  end

  class String < Validator
    def validate(data)
      return failure('Not a String') unless data.is_a? ::String
      return failure('Should not be blank') if !@options[:allow_blank] && data.empty? 
      return failure('Too short') if @options[:min_length] && data.size < @options[:min_length]
      return failure('Too long') if @options[:max_length] && data.size > @options[:max_length]
      if @options[:regex]
        match = @options[:regex].match(data)
        return failure('Does not match') unless match
        return match
      end
      data
    end

    def convert(data)
      if data.is_a? MatchData
        data.string
      else
        data
      end
    end
  end

  class Symbol < Validator
    def prepare
      @sym = @args.first.to_sym
      @str = @args.first.to_s.freeze
    end

    def validate(data)
      case data
      when ::String
        @str == data ? @sym : failure('Not equal')
      when ::Symbol
        @sym == data ? @sym : failure('Not equal')
      else
        failure('Not a String or a Symbol')
      end
    end
  end

  class Array < Validator
    def prepare
      @cls = Trafaret.get_validator(@options[:validator]).new @options
    end

    def self.[](validator, options = {})
      self.new(options.merge(validator: validator))
    end

    def validate(data)
      return failure('Not an Array') unless data.is_a? ::Array
      fails = {}
      res = data.map.with_index do |elem, index|
        val = @cls.call elem
        fails[index] = val if val.is_a? Trafaret::Error
        val
      end
      if fails.blank?
        return res
      else
        return failure(fails)
      end
    end
  end
end