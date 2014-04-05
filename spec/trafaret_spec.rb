# -*- coding: utf-8 -*-
require 'trafaret'

T = Trafaret

class ProviderTrafaret < Trafaret::Base
  key :url, T.string(min_length: 3, max_length: 50)
end

class FacebookResponseTrafaret < Trafaret::Base
  key :name, T.string(min_length: 2), optional: true
  extract :providers do |data|
    data['oa'].flat_map do |prov_name, accs|
      accs.map { |uuid, data| data }
    end
  end
  key :providers, T::Array[:provider_trafaret]
  key :dwarf, :string, default: 'Sniffer'
  key :optional_key, :string, optional: true
end

describe Trafaret::Base do
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
    T.key(:name, :string).call({name: 'cow'}).should == [:name, 'cow']
    T.key(:name, :string, default: 'Elephant').call({}).should == [:name, 'Elephant']
    T.key(:name, :string, optional: true).call({}).should == nil
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