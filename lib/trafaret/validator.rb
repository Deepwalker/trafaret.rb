class Trafaret::Validator
  def initialize(options = {}, &blk)
    @options = options
    @blk = blk
  end

  def validate(data)
    if @blk
      @blk.call(data)
    else
      data # or return Trafaret::Error
    end
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
    Trafaret::Or.new(self, other)
  end

  # Helpers
  def failure(msg)
    Trafaret::Error.new msg
  end
end