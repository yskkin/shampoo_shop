# -*- coding: utf-8 -*-

require 'csv'
require 'wombat'

class ShampooList
  include Wombat::Crawler

  base_url 'http://www.ishampoo.jp/'
  path '/list/productListS'

  product_link 'xpath=//table//tr/td[3]/a/@href', :list do |hrefs|
    hrefs.map do |href|
      href.gsub('../', '')
    end
  end
end

class ProductPage
  include Wombat::Crawler

  base_url 'http://www.ishampoo.jp/'

  製品名 css: '.row .container h2'
  メーカ css: '.row .container small'
  参考価格 css: '.row .container' do |text|
    text.match(/\[参考価格\](\d+)円/)[1]
  end
  容量 css: '.row .container' do |text|
    text.match(/容量(\d+)ml/)[1]
  end
  総合順位 xpath: '//*[contains(text(), "総合順位")]/following-sibling::*' do |text|
    text.match(/(\d+)位/)[1]
  end

  総合評価 xpath: '//*[contains(text(), "総合評価")]/following-sibling::*'

  %w(洗浄力 素材 安全性 コスパ 環境 補修力 ツヤ 感触 育毛 洗浄剤).each_with_index do |sym, i|
    color = sym + 'の色'
    color_xpath = "xpath=(//progress)[#{i + 1}]/@class"
    xpath = "xpath=(//progress)[#{i + 1}]/@value"

    send sym, xpath
    send color.to_sym, color_xpath do |text|
      text.match(/progress-([a-z]+)/)[1]
    end
  end


  成分数 xpath: '//table//tr[2]/td[1]'
  洗浄剤数 xpath: '//table//tr[2]/td[2]'
  エキス系 xpath: '//table//tr[2]/td[3]'
  特効 xpath: '//table//tr[2]/td[4]'
  ダメ xpath: '//table/tr[2]/td[5]'

  コメント css: '.kaisekitext'
  全成分 xpath: '//div[contains(text(), "【全成分】")]' do |text|
    text.gsub('【全成分】', '').strip
  end
  宣伝文 xpath: '//div[contains(text(), "【宣伝文】")]' do |text|
    text.gsub('【宣伝文】', '').strip
  end
end

ShampooList.new.crawl['product_link'].map do |path|
  a = ProductPage.new
  a.path path
  data = a.crawl
  $csv ||= CSV.open 'shampoo.csv', 'wb', headers: data.keys, write_headers: true
  $csv << data.values
end
