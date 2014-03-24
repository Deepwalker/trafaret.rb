class Trafaret::Validator
  def initialize(options = {})
    @options = options
  end

  def validate(data)
    data # or return Trafaret::Error
  end

  def convert(data)
    data
  end

  def call(data)
    val = validate(data)
    return val if val.is_a? Trafaret::Error
    if block_given?
      yield val
    else
      convert(val)
    end
  end

  # ADT
  def |(other)
    Trafaret::Or(self, other)
  end
end