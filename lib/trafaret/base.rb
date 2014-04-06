module Trafaret
  class Key
    def initialize(name, validator, options = {}, &blk)
      validator = Trafaret.get_validator(validator)
      @name = name
      @validator = if validator.is_a?(Class) then validator.new(options) else validator end
      @validator.add(blk) if blk
      @options = options
      @optional = options[:optional]
      @default = options[:default]
      @to_name = options[:to_name] || name
    end

    def get(obj)
      data = begin
               obj.send(@name)
             rescue NameError
               nil
             end
      data ||= begin
                 obj[@name] || obj[@name.to_s]
               rescue NoMethodError, TypeError
                 nil
               end
      data ||= @default if @default
      data
    end

    def call(data)
      value = get(data)
      return unless value || !@optional
      value = @validator.call(value, &@blk)
      [@to_name, value]
    end
  end

  class Base < Validator
    module ClassMethods
      attr_accessor :keys, :extractors
      def inherited(base)
        base.keys = (keys || []).dup
        base.extractors = (extractors || {}).dup
      end

      def key(name, validator, options = {}, &blk)
        @keys << Key.new(name, validator, options, &blk)
      end

    end
    extend ClassMethods

    attr_accessor :keys

    def prepare
      @keys = @options[:keys] || []
      @keys.concat(self.class.keys || [])
    end

    def validate(data)
      res = []
      fails = []
      @keys.each do |key|
        vdata = key.call(data)
        next unless vdata
        if vdata[1].is_a? Trafaret::Error
          fails << vdata
        else
          res << vdata
        end
      end
      if fails.blank?
        Hash[res]
      else
        failure(Hash[fails])
      end
    end
  end
end