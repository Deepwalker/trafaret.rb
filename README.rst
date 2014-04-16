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