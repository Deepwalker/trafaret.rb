# -*- coding: utf-8 -*-
require 'trafaret'

class ProviderTrafaret < Trafaret::Base
  key :url, Trafaret::String, min_length: 3, max_length: 50
end

class FacebookResponseTrafaret < Trafaret::Base
  key :name, :string, optional: true, min_length: 2
  extract :providers do |data|
    data['oa'].flat_map do |prov_name, accs|
      accs.map { |uuid, data| data }
    end
  end
  key :providers, :array, validator: :provider_trafaret
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
    FacebookResponseTrafaret.new.call(raw).should == ({name: "kuku", providers: [{url: "http://ya.ru"}, {url: "http://www.ru"}]})
  end
end

describe Trafaret::String do
  it 'should check errors' do
    Trafaret.string.call('').message.should == 'Should not be blank'
    Trafaret.string(min_length: 10).call('abc').message.should == 'Too short'
    Trafaret.string(max_length: 1).call('abc').message.should == 'Too long'
    Trafaret.string(regex: /abc/).call('bca').message.should == 'Does not match'
  end
end

describe Trafaret::Array do
  it 'should check' do
    Trafaret::Array[:string].call(['a', 'b', 'c']).should == ['a', 'b', 'c']
  end
end

describe Trafaret::Or do
  it 'should return value' do
    Trafaret[:or, [:string, :integer]].call('krukatuka').should == 'krukatuka'

    (Trafaret[:string] | Trafaret[:integer]).call('krukatuka').should == 'krukatuka'

    (Trafaret.string | Trafaret.integer).call('krukatuka').should == 'krukatuka'
  end

  it 'should return errors' do
    Trafaret[:or, Trafaret[:array, validator: :string]].call('krukatuka').message.first.message.should == 'Not an Array'
  end
end