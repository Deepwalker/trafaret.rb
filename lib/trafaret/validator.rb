class Trafaret::Validator
  def initialize(*args, &blk)
    @options = (args.pop if args.last.is_a? Hash) || {}
    @args = args
    @blk = blk

    prepare
  end

  def prepare
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

  def &(other)
    Trafaret::Chain.new(self, other)
  end

  # Helpers
  def failure(msg)
    Trafaret::Error.new msg
  end
end