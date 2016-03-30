class MenuItem < ActiveRecord::Base

  CATEGORIES = %w{ pizze insalate cucina }.freeze

  URLS = {
    pizze: 'http://www.orostube.it/products-list/4',
    insalate: 'http://www.orostube.it/products-list/12',
    cucina: 'http://www.orostube.it/products-list/5'
  }.freeze

  EMOJIS = {
    pizze: "\u{1f355}",
    insalate: "\u{1f372}",
    cucina: "\u{1f331}"
  }.freeze

  CATEGORIES.each do |c|
    scope c.to_sym, ->{ where(category: c) }
  end

end
