require 'active_support/core_ext'
require 'trafaret/version'
require 'trafaret/errors'
require 'trafaret/validator'
require 'trafaret/validators'
require 'trafaret/base'

module Trafaret
  def self.get_validator(validator, options = {})
    if validator.is_a? Symbol
      class_name = validator.to_s.classify
      validator = Trafaret.const_get(class_name) rescue nil
      validator ||= Kernel.const_get(class_name)
    else
      validator
    end
  end
end