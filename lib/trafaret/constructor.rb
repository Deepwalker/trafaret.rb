module Trafaret
  class Constructor
    class << self
      def construct_from(from)
        case from
        when ::Hash
          from_hash(from)
        when ::Array
          from_array(from)
        when ::Symbol
          Trafaret.get_instantiated_validator from
        when Trafaret::Validator
          from
        when ::Proc
          Trafaret::Proc.new &from
        else
          raise 'Wrong parameter'
        end
      end

      def from_hash(params)
        keys = []
        params.each do |k, v|
          v = Trafaret::Constructor.construct_from v
          if k.is_a? ::Symbol
            keys << Key.new(k, validator: v)
          elsif k.is_a? Trafaret::Key
            k.set_validator(v)
            keys << k
          end
        end
        Trafaret::Base.new keys: keys
      end

      def from_array(params)
        if params.size == 1
          Trafaret::Array.new validator: Trafaret::Constructor.construct_from(params[0])
        else params.size > 1
          Trafaret::Tuple.new(*(params.map { |p| Trafaret::Constructor.construct_from(p) }))
        end
      end
    end
  end
end