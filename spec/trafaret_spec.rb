# -*- coding: utf-8 -*-
require 'trafaret'

describe Trafaret do
  Provider = Trafaret::Hash.new do
    attribute :url
  end

  Checker = Trafaret::Hash.new do
    attribute :name
    array :providers, class: Provider do |obj|
      obj['oa'].flat_map do |prov_name, accs|
        accs.map {|uuid, data| data}
      end
    end
  end

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
    Checker.dump(raw).should == ({"name"=>"kuku", "providers"=>[{"url"=>"http://ya.ru"}, {"url"=>"http://www.ru"}]})
  end
end
