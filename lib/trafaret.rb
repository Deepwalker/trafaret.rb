require 'active_support/core_ext'
require 'trafaret/version'
require 'trafaret/errors'
require 'trafaret/validator'
require 'trafaret/validators'
require 'trafaret/numeric'
require 'trafaret/uri_email'
require 'trafaret/hash'
require 'trafaret/constructor'

module Trafaret
  module NoValue
  end

  class << self
    def get_validator(validator)
      if validator.is_a? ::Symbol
        class_name = validator.to_s.split('_').collect!{ |w| w.capitalize }.join
        validator = Trafaret.const_get(class_name) rescue nil
        validator ||= Kernel.const_get(class_name)
      else
        validator
      end
    end

    def get_instantiated_validator(validator, options = {})
      val = self.get_validator(validator)
      val = val.new(options) if val.is_a? Class
      val
    end

    def [](validator, options = {})
      return self.get_instantiated_validator(validator, options)
    end

    def method_missing(meth, *args, &blk)
      cls = self.get_validator(meth)
      if cls
        cls.new(*args, &blk)
      else
        super
      end
    end

    def proc(*args, &blk)
      Trafaret::Proc.new *args, &blk
    end

    def failure(msg)
      Trafaret::Error.new msg
    end

    def construct(from)
      Trafaret::Constructor.construct_from(from)
    end

    alias :f :failure
  end
end