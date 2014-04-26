# -*- coding: utf-8 -*-
require 'trafaret'

T = Trafaret

class FacebookResponseTrafaret < Trafaret::Hash
  key :name, T.string(min_length: 2), optional: true
  key :oa, T.mapping(T.string,
    T.mapping(T.string,
      T[:hash, keys: [T.key(:url, validator: T.string)]]
    )
  ), to_name: :providers do |data| # so we have response that matches our assumptions, then we can convert it
    data.flat_map { |p_n, accs| accs.map { |uuid, data| data } }
  end
  key :dwarf, :string, default: 'Sniffer'
  key :optional_key, :string, optional: true
end

describe Trafaret::Hash do
  let :raw do
    {'name' => 'kuku',
     'oa' => {
       'facebook' => {
         '124234234234234' => {'url' => 'http://ya.ru'},
         '124234234234235' => {'url' => 'http://www.ru'}
       }
     }
    }
  end
  it 'should work' do
    FacebookResponseTrafaret.new.call(raw).should == ({name: "kuku", providers: [{url: "http://ya.ru"}, {url: "http://www.ru"}], dwarf: 'Sniffer'})
  end

  it 'should work with hash' do
    t = T.construct({
      kuku: :integer,
      T.key(:krkr, to_name: :id) => :string,
      hash: {
        karma: :integer
      },
      array: [{id: :integer}],
      tuple: [:integer, :nil],
      proc_: proc { |d| d },
      just_trafaret: T.nil
    })
    res = t.call({kuku: 123, krkr: 'karma', hash: {karma: 234}, array: [{id: 123}, {id: 234}], proc_: 123, just_trafaret: nil, tuple: [123, nil]})
    res[:id].should == 'karma'
    res[:hash][:karma].should == 234
    res[:proc_].should == 123
  end
end

describe Trafaret::String do
  it 'should check errors' do
    T.string.call('').message.should == 'Should not be blank'
    T.string(min_length: 10).call('abc').message.should == 'Too short'
    T.string(max_length: 1).call('abc').message.should == 'Too long'
    T.string(regex: /abc/).call('bca').message.should == 'Does not match'
  end
end

describe Trafaret::Integer do
  it 'should check errors' do
    T.integer.call('blabla').message.should == 'Not an Integer'
    T.integer(lt: 5).call(5).message.should == 'Too big'
    T.integer(lte: 5).call(6).message.should == 'Too big'
    T.integer(gt: 5).call(5).message.should == 'Too small'
    T.integer(gte: 5).call(4).message.should == 'Too small'
  end
end

describe Trafaret::Validator do
  it 'should work with block' do
    blk = proc { |data| if data.present? then data else T::Error.new('Empty data') end }
    T::Validator.new(&blk).call('argh').should == 'argh'
    T::Validator.new(&blk).call('').message.should == 'Empty data'
    T.proc(&blk).call('').message.should == 'Empty data'
  end
end

describe Trafaret::Array do
  it 'should check' do
    T::Array[:string].call(['a', 'b', 'c']).should == ['a', 'b', 'c']
    T::Array[:string].call(['a', 'b', nil]).should.is_a? Trafaret::Error
  end
end

describe Trafaret::Or do
  it 'should return value' do
    T[:or, [:string, :integer]].call('krukatuka').should == 'krukatuka'

    (T[:string] | T[:integer]).call('krukatuka').should == 'krukatuka'

    (T.string | T.integer).call('krukatuka').should == 'krukatuka'
  end

  it 'should return errors' do
    T[:or, T[:array, validator: :string]].call('krukatuka').message.first.message.should == 'Not an Array'
  end

  it 'should properly chained' do
    (T.string(min_length: 100) | T.integer | T.string(regex: /aaa/)).call('aaa').should == 'aaa'
  end
end

describe Trafaret::Chain do
  it 'should work with callables' do
    trafaret = T.integer & proc { |d| d == 123? d : T.f('not equal') }
    trafaret.call(123).should == 123
    trafaret.call(321).message.should == 'not equal'
    trafaret = T.integer & proc { |d| d }
    trafaret.call('abc').message.should == 'Not an Integer'
  end
end


describe Trafaret::Key do
  it 'should extract and check value' do
    T.key(:name, validator: :string).call({name: 'cow'}).should == [:name, 'cow']
    T.key(:name, validator: :string, default: 'Elephant').call({}).should == [:name, 'Elephant']
    T.key(:name, validator: :string, optional: true).call({}).should == nil
    # to name test
    T.key(:name, validator: :string, to_name: :id).call({name: '123'}).should == [:id, '123']
    T.key(:name, validator: :string, to_name: :id).call({name: 123})[0].should == :name
  end
end

describe Trafaret::Symbol do
  it 'should check equality' do
    T.symbol(:name).call('name').should == :name
    T.symbol(:name).call(:name).should == :name
  end

  it 'should fail' do
    T.symbol(:name).call('pame').message.should == 'Not equal'
    T.symbol(:name).call(123).message.should == 'Not a String or a Symbol'
  end
end

describe Trafaret::Nil do
  it 'should check for nil' do
    n = T::Nil.new
    n.call(123).message.should == 'Value must be nil'
    n.call(nil).should == nil
  end
end

describe Trafaret::Validator do
  it 'must work with case' do
    caser = proc do |a|
      case a
      when T.integer
        :int
      when T.symbol(:k)
        :symbol
      else
        :any
      end
    end
    caser.call(123).should == :int
    caser.call(:k).should == :symbol
    caser.call('asd').should == :any
  end
end

describe Trafaret::Case do
  it 'must case options' do
    cs = T.case do |c|
      c.when(T.integer) { |r| :int }
      c.when(T.string) { |r| :string }
      c.when(T.nil) { |r| :nil }
    end
    cs.call(123).should == :int
    cs.call('123').should == :int
    cs.call('abs').should == :string
    cs.call(nil).should == :nil
  end
end

describe Trafaret::Tuple do
  it 'must match tuple' do
    t = T.tuple(:integer, :string, :nil)
    t.call([1, 'a', nil]).should == [1, 'a', nil]
    t.call([1, 'a', 3]).dump.should == {2 => 'Value must be nil'}
  end
end

describe Trafaret::URI do
  it 'must match uri' do
    t = T.uri(schemes: ['http', 'https'])
    t.call('http://ya.ru:80').should == 'http://ya.ru'
  end
end

describe Trafaret::Email do
  it 'must parse email' do
    e = T.email.to { |m| m[:name] }
    e.call('kuku@gmail.com').should == 'kuku'
  end
end

describe Trafaret::Forward do
  it 'should provide recursive' do
    fwd = Trafaret.forward
    v = T.construct(T.key(:child, optional: true) => fwd, payload: :string)
    fwd.provide v
    res = v.call({child: {child: {payload: 'kuku'}, payload: '123'}, payload: '321'})
    res[:child][:child][:payload].should == 'kuku'
  end
end