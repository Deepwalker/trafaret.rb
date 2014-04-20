Trafaret
========

Trafaret is lib for data parsing.

You can want this first::

  T = Trafaret

Small example for one of ways to construct Trafaret::

  T.construct({
    id: :integer,
    post_ids: [:integer],
    users: [{name: :string, id: :integer}],
    proc_: proc { |a| a == 3 ? a : T.failure('Not a 3') }
  })

Trafarets supports ``|`` and ``&`` operations::

  (T.symbol(:t) | T.symbol(:a)).call(:t) == :t

  (T.string.to(&:to_i) & T.integer).call('123') == 123

You can attach converter to trafaret with ``to``::

  T.string(regex: /\A\d+\Z/).to { |match| match.string.to_i }.call('123')

  T.string(regex: /\A\d+\Z/).to(&:string).to(&:to_i).call('123')

Any callable can be used as ``Trafaret`` while it use simple convention. If data ok, you return something, if it wrong
you must return ``Trafaret::Error`` instance with message. Correct message can be a string or a Hash with simple keys and Errors values::

  irb> (T.string & T.proc { |data| data == 'karramba' ? 'Bart' : T.failure('Not a Bart text!')}).call ('ku')
  => #<Trafaret::Error("Not a Bart text!")>
  irb> (T.string & T.proc { |data| data == 'karramba' ? 'Bart' : T.failure('Not a Bart text!')}).call ('karramba')
  => "Bart"

Numeric
-------

Two trafarets Integer and Float supports common interface. In options this is parameters `lt`, `lte`, `gt`, `gte`.

Example::

  T.integer(gt: 3, lt: 5).call(4) == 4
  T.float(gt:3, lt: 5).call(4.3) == 4.3

String
------

Parameters `allow_blank`, `min_length`, `max_length`. And special option `regex`.

Example::

  T.string.call('kuku') == 'kuku'
  T.string(regex: /\Akuku\z/).call('kuku') == 'kuku'

If you use custom converter block, you will get `Match` instead of `String`, so you can use regex result::

  T.string(regex: /\Ayear=(\d+),month=(\d+),day=(\d+)\z/).to {|m| Date.new(*m.to_a[1..3].map(&:to_i)) }.call('year=2012,month=5,day=4').to_s == '2012-05-04'

Array
-----

Get one important parameter `validator` that will be applied to every array element::

  T.array(validator: :integer).call(['1','2','3']) == [1,2,3]

Case
----

You can use Ruby case with trafarets, but this have not much sense::

  case 123
  when T.integer
    :integer
  else
    :any
  end

And you can use `Trafaret::Case` that puts result of trafaret to when clause::

  cs = T.case do |c|
    c.when(T.integer) { |r| :int }
    c.when(T.string) { |r| :string }
    c.when(T.nil) { |r| :nil }
  end

Tuple
-----

Tuple is Array that consists not from any number of similar elements, but from exact number of different ones.
`[1,2,3]` - Array of ints.
`[1, 'a', nil]` - Tuple.

Example::

  t = T.tuple(:integer, :string, :nil)
  t.call([1, 'a', nil]) == [1, 'a', nil]
  t.call([1, 'a', 3]).dump == {2 => 'Value must be nil'} # Error dumped to pure structures