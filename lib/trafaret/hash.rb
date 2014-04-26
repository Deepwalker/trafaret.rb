module Trafaret
  class Key
    def initialize(name, options = {}, &blk)
      @name = name
      @sname = name.to_s

      @optional = options.delete(:optional)
      @default = options.delete(:default)
      @to_name = options.delete(:to_name) || name
      validator = options.delete(:validator)
      @options = options

      set_validator(validator, options, &blk) if validator
    end

    def set_validator(validator, options = {}, &blk)
      validator = Trafaret.get_validator(validator)
      @validator = if validator.is_a?(Class) then validator.new(options) else validator end
      @validator.add(blk) if blk
    end

    def get(obj)
      # data = obj.send(@name) if data.respond_to? @name
      if obj.include? @name
        obj[@name]
      elsif obj.include? @sname
        obj[@sname]
      else
        NoValue
      end
    end

    def call(data)
      value = get(data)
      if value == NoValue
        if @default
          value = @default
        elsif @optional
          return
        else
          return [@name, Trafaret::Error.new("#{@name} is required")]
        end
      end
      value = @validator.call(value, &@blk)
      if value.is_a? Trafaret::Error
        [@name, value]
      else
        [@to_name, value]
      end
    end
  end

  class Hash < Validator
    module ClassMethods
      attr_accessor :keys
      def inherited(base)
        base.keys = (keys || []).dup
      end

      def key(name, validator, options = {}, &blk)
        @keys << Key.new(name, options.merge(validator: validator), &blk)
      end
    end
    extend ClassMethods

    attr_accessor :keys

    def prepare
      @keys = @options[:keys] || []
      @keys.concat(self.class.keys || [])
    end

    def key(name, validator, options = {}, &blk)
      @keys << Key.new(name, validator, options.merge(validator: validator), &blk)
    end

    def validate(data)
      return failure('Not a Hash') unless data.is_a?(::Hash)
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
        ::Hash[res]
      else
        failure(::Hash[fails])
      end
    end
  end
end