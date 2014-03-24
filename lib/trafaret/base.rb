module Trafaret
  class Key
    def initialize(name, validator, options = {}, &blk)
      @name = name
      @validator = validator.new(options)
      @options = options
      @blk = blk
    end

    def get(obj, extractors = {})
      return @blk.call obj if @blk
      data = begin
               extractors[@name].call(obj) if extractors[@name]
             rescue NoMethodError
               nil
             end
      data ||= begin
               obj.send(@name)
             rescue NameError
               nil
             end
      data ||= begin
                 obj[@name] || obj[@name.to_s]
               rescue NoMethodError, TypeError
                 nil
               end
    end

    def call(data, extractors = {})
      [@name, @validator.call(get(data, extractors), &@blk)]
    end
  end

  class Extractor
    def initialize(&blk)
      @blk = blk
    end

    def call(data)
      @blk.call data
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
        @keys << Key.new(name, Trafaret.get_validator(validator), options, &blk)
      end

      def extract(name, &blk)
        @extractors[name] = Extractor.new(&blk)
      end
    end
    extend ClassMethods

    def validate(data)
      res = []
      self.class.keys.each do |key|
        res << key.call(data, extractors = self.class.extractors)
      end
      Hash[res]
    end
  end
end