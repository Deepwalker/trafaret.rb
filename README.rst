Trafaret
========

Trafaret is a library for data parsing. Use it anywhere to check and convert data. 

Trafaret is suitable to use in place of strong parameters, POST and GET data parsing, JSON matchers in spec, and more. 
  
Checking data is important, and you often need to do something with data based on it type, due fact that Trafaret supports ADT like
data description.

You may want this first::

  T = Trafaret

Example of a way to construct Trafaret::

  T.construct({
    id: :integer,
    post_ids: [:integer],
    users: [{name: :string, id: :integer}],
    proc_: proc { |a| a == 3 ? a : T.failure('Not a 3') }
  })

Trafaret supports ``|`` and ``&`` operations::

  (T.symbol(:t) | T.symbol(:a)).call(:t) == :t

  (T.string.to(&:to_i) & T.integer).call('123') == 123

You can attach converter to Trafaret with ``to``::

  T.string(regex: /\A\d+\Z/).to { |match| match.string.to_i }.call('123')

  T.string(regex: /\A\d+\Z/).to(&:string).to(&:to_i).call('123')

Any callable can be used as ``Trafaret`` while it use simple convention. If the data are correct, then you return something; if the data are incorrect, then 
you return ``Trafaret::Error`` instance and an error message. A correct message can be a string or a Hash with simple keys and Errors values::

  irb> (T.string & T.proc { |data| data == 'karramba' ? 'Bart' : T.failure('Not a Bart text!')}).call ('ku')
  => #<Trafaret::Error("Not a Bart text!")>
  irb> (T.string & T.proc { |data| data == 'karramba' ? 'Bart' : T.failure('Not a Bart text!')}).call ('karramba')
  => "Bart"

Numeric
-------

Trafaret ``Integer`` and ``Float`` use a common interface. In the options, the parameters are ``lt``, ``lte``, ``gt``, ``gte``.

Example::

  T.integer(gt: 3, lt: 5).call(4) == 4
  T.float(gt:3, lt: 5).call(4.3) == 4.3

String
------

Parameters ``allow_blank``, ``min_length``, ``max_length``. And special option ``regex``.

Example::

  T.string.call('kuku') == 'kuku'
  T.string(regex: /\Akuku\Z/).call('kuku') == 'kuku'

If you use a custom converter block, you will get ``Match`` instead of ``String``, so you can use regex result::

  T.string(regex: /\Ayear=(\d+),month=(\d+),day=(\d+)\Z/).to {|m| Date.new(*m.to_a[1..3].map(&:to_i)) }.call('year=2012,month=5,day=4').to_s == '2012-05-04'

URI
---

URI parses URI. Parameter ``schemes``, by default == ['http', 'https']::

  t = T.uri(schemes: ['ftp'])
  t.call('ftp://ftp.ueaysuc.co.uk.edu') == 'ftp://ftp.ueaysuc.co.uk.edu'

Possible Errors - 'Invalid scheme', 'Invalid URI'.

Mail
----

Now just checks simple regexp::

  T.email('kuku@example.com').to { |m| m[:name] } == 'kuku'

Array
-----

Get one important parameter ``validator`` that will be applied to every array element::

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

And you can use ``Trafaret::Case`` that puts result of trafaret to when clause::

  cs = T.case do |c|
    c.when(T.integer) { |r| :int }
    c.when(T.string) { |r| :string }
    c.when(T.nil) { |r| :nil }
  end

Tuple
-----

Tuple is Array that consists not from any number of similar elements, but from exact number of different ones.
``[1,2,3]`` - Array of ints.
``[1, 'a', nil]`` - Tuple.

Example::

  t = T.tuple(:integer, :string, :nil)
  t.call([1, 'a', nil]) == [1, 'a', nil]
  t.call([1, 'a', 3]).dump == {2 => 'Value must be nil'} # Error dumped to pure structures

Hash
----

Hashes work in pair with ``Key``'s::

  T::Hash.new(keys: [T.key(:field_name, validator: T.string)])

Keys are powerful and we have syntax sugar::

  T.construct(
    kuku: :integer,
    T.key(:opt_field, optional: true) => T.integer
  )
