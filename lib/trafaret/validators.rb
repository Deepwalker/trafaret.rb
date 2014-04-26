module Trafaret
  class Any < Validator
  end

  class ADT < Validator
    attr_reader :validators

    def prepare(*args)
      @args = @args.first if @args.first.is_a? ::Array
      @validators = @args.map { |v| Trafaret.get_instantiated_validator(v) }
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

  class Forward < Validator
    attr_accessor :validator

    def provide(validator)
      @validator = validator
    end

    def validate(data)
      raise 'Validator is not provided' unless validator
      validator.validate(data)
    end
  end

  class Nil < Validator
    def validate(data)
      failure('Value must be nil') unless data.nil?
    end
  end

  class String < Validator
    def prepare
      @regex = ::Regexp.compile @options[:regex] if @options[:regex]
    end

    def validate(data)
      return failure('Not a String') unless data.is_a? ::String
      return failure('Should not be blank') if !@options[:allow_blank] && data.empty? 
      return failure('Too short') if @options[:min_length] && data.size < @options[:min_length]
      return failure('Too long') if @options[:max_length] && data.size > @options[:max_length]
      if @regex
        match = @regex.match(data)
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
      @cls = Trafaret.get_instantiated_validator(@options.delete(:validator), @options)
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

  class Mapping < Validator
    def prepare
      @key_validator = @args.first
      @value_validator = @args[1]
    end

    def validate(data)
      return failure('Not a Hash') unless data.is_a? ::Hash
      fails = []
      pairs = []
      data.each do |k, v|
        kv = @key_validator.call(k)
        vv = @value_validator.call(v)
        if (kv.is_a? Trafaret::Error) || (vv.is_a? Trafaret::Error)
          fails << [k, [kv, vv]]
        else
          pairs << [kv, vv]
        end
      end
      if fails.blank?
        ::Hash[pairs]
      else
        failure(::Hash[fails])
      end
    end
  end

  class Proc < Validator
    def prepare
      raise 'Need to call with block' if @converters.blank?
      @blk = @converters.pop
    end

    def validate(data)
      @blk.call(data)
    end
  end

  class Case < Validator
    def prepare
      @whens = []
      @converters.shift.call(self)
    end

    def when(trafaret, &blk)
      @whens << [Trafaret::Constructor.construct_from(trafaret), blk]
    end

    def call(data)
      @whens.each do |trafaret, blk|
        val = trafaret.call(data)
        unless val.is_a?(Trafaret::Error)
          return blk.call(val)
        end
      end
      failure('Case does not match')
    end
  end

  class Tuple < Validator
    def prepare
      @validators = @args.map { |arg| Trafaret.get_instantiated_validator(arg) }
      @size = @validators.size
    end

    def call(data)
      return failure('Too many elements') if data.size > @size# && !@extra
      return failure('Not enough elements') if data.size < @size
      failures = {}
      result = []
      data[0..@size].each.with_index do |el, index|
        val = @validators[index].call(el)
        result << val
        failures[index] = val if val.is_a? Trafaret::Error
      end
      if failures.empty?
        result
      else
        failure(failures)
      end
    end
  end
end