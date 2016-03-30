require 'nokogiri'
require 'open-uri'
require './models/menu_item'

class MenuBuilder

  def self.retrieve category
    items = MenuItem.send(category.to_sym)
    last_update = items.map(&:retrieved_at).max if items.any?

    if items.empty? or ((last_update - Time.now.to_i) >= (60))
      rebuild_db category
    else
      items
    end
  end

  def self.emoji_for category
    MenuItem::EMOJIS[category]
  end

  private

  def self.rebuild_db category
    MenuItem.send(category.to_sym).delete_all

    url = MenuItem::URLS[category.to_sym]

    items = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby')).css(".scroll-content-item>.prod")
    names = items.map do |p|
      name = p.css("p.title-price").first.text.strip
      "#{emoji_for(category)} #{name}"
    end
    ingredients = items.map {|p| p.attr("title").strip}
    prices = items.map {|p| p.attr("price").strip.to_f }

    menu_items = names.zip(ingredients, prices).map do |i|
      h = Hash[[:name, :ingredients, :price].zip(i)]
      h[:retrieved_at] = Time.now
      h[:category] = category
      h
    end

    menu_items.map do |mi|
      MenuItem.create(mi)
    end

  end

end
