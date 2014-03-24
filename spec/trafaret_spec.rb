# -*- coding: utf-8 -*-
require 'trafaret'

class ProviderTrafaret < Trafaret::Base
  key :url, Trafaret::String, min_length: 3, max_length: 50
end

class FacebookResponseTrafaret < Trafaret::Base
  key :name, :string, optional: true, min_length: 5
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