class Trafaret::Validator
  attr_accessor :converters, :options

  def initialize(*args, &blk)
    @options = (args.pop if args.last.is_a? ::Hash) || {}
    @args = args
    @converters = []
    @converters << blk if blk

    prepare
  end

  def prepare
  end

  def validate(data)
    data # or return Trafaret::Error
  end

  def convert(data)
    data
  end

  def perform_convert(data)
    if @converters.blank?
      convert(data)
    else
      @converters.each do |c|
        data = c.call(data)
        break if data.is_a? Trafaret::Error
      end
      data
    end
  end

  def call(data)
    val = validate(data)
    return val if val.is_a? Trafaret::Error
    if block_given?
      yield val
    else
      perform_convert(val)
    end
  end

  def add(blk)
    @converters << blk
  end

  def to (&blk)
    @converters << blk
    self
  end

  def ===(data)
    !validate(data).is_a?(Trafaret::Error)
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