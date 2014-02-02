require "trafaret/version"

module Trafaret
  class Attribute
    def initialize(name, options = {}, &blk)
      @name = name
      @options = options
      @blk = blk
    end

    def name
      @name.to_s
    end

    def get(obj)
      if @blk
        return @blk.call obj
      end
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
    end

    alias :dump :get
  end

  class Array < Attribute
    def dump(obj)
      cls = @options[:class]
      if data = get(obj)
        data.map do |elem|
          cls.dump elem
        end
      else
        []
      end
    end
  end

  class Hash < Attribute
    def initialize(name = nil, options = {}, &blk)
      @name = name
      @options = options
      @attrs = options[:attributes] || []
      instance_eval(&blk)
    end

    def attribute(name, options = {}, &blk)
      @attrs << Attribute.new(name, options, &blk)
    end

    def array(name, options = {}, &blk)
      @attrs << Array.new(name, options, &blk)
    end

    def hash(name, options = {}, &blk)
      @attrs << Hash.new(name, options = {}, &blk)
    end

    def dump(obj)
      res = {}
      data = if @name then get(obj) else obj end
      @attrs.each do |attr|
        res[attr.name] = attr.dump(data)
      end
      res
    end
  end
end