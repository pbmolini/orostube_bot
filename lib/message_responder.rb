require './models/user'
require './models/order'
require './lib/message_sender'
require './lib/menu_builder'
# require 'nokogiri'
# require 'open-uri'
require 'date'
require 'pry'

class MessageResponder
  attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = User.find_or_create_by(uid: message.from.id)
    if message.chat.id != @user.chat_id
      @user.update_attributes chat_id: message.chat.id
    end
    @pietro = User.first
  end

  def respond

    on /^\/reset/ do
      @user.update_attributes state: nil
      answer_with_reset_message
    end

    case @user.state
    when 'ordering'
      on /(Pizze|Insalate|Cucina)/ do |category|
        @user.update_attributes state: "choosing_#{category.downcase.to_s}"
        answer_with_menu category.downcase.to_sym
      end
    when /choosing_[#{MenuItem::CATEGORIES.join('|')}]/
      on /Indietro/ do
        go_to_start_menu
      end

      on /Menu/ do
        answer_with_menu @user.state.gsub('choosing_','')
      end

      on /^Ordina (.+)/ do |name|
        choose_meal_and_notify_pietro name
        @user.update_attributes state: nil
      end

      on /^(?!.*(Indietro|Ordina|Menu)).*$/ do
         answer_with_details
      end
    when 'deleting'
      on /^Elimina (.+)/ do |name|
        remove_meal_from_order name
        @user.update_attributes state: nil
      end
    else
      on /^\/start/ do
        go_to_start_menu
      end

      on /^\/help/ do
        display_help
      end

      on /^\/ordini/ do
        answer_with_orders
      end

      on /^\/cancella/ do
        go_to_delete_menu
      end

      # on /^\/ordinato/ do
      #   ask_for_discounts
      # end

      # binding.pry
      # if message.reply_to_message.present? and message.reply_to_message.text.match(/^\/ordinato/)
      #   on /^(\d+)$/ do |n_discounts|
      #     send_price_per_person n_discounts.to_i
      #   end
      # end

    end

  end

  private

  def on regex, &block
    regex =~ message.text

    if $~
      case block.arity
      when 0
        yield
      when 1
        yield $1
      end
    end

  end

  def go_to_start_menu
    answer_with_start_menu
    @user.update_attributes state: "ordering"
  end

  def answer_with_start_menu
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Pizza, insalata o qualcosa dalla cucina?",
                      answers: [
                        "#{MenuBuilder.emoji_for(:pizze)} Pizze",
                        "#{MenuBuilder.emoji_for(:insalate)} Insalate",
                        "#{MenuBuilder.emoji_for(:cucina)} Cucina"
                      ]).send
  end

  def answer_with_menu category
    items = MenuBuilder.retrieve(category)
    names = items.map(&:name)
    names.any? ? display_keyboard_for(names + ["\u{25c0} Indietro"]) : answer_with_orostube_closed
  end

  def answer_with_details
    item = MenuItem.find_by(name: message.text)
    if item.present?
      MessageSender.new(bot: bot,
                        chat: message.chat,
                        text: %{
                          *#{message.text}*
                          *Ingredienti:* #{item.ingredients}
                          *Prezzo:* #{item.price}0 €
                        }.gsub(/^[\s]+/, ""),
                        parse_mode: 'Markdown',
                        answers: ["\u{1f374} Menu", "Ordina #{item.name}"]
                        ).send
    else
      MessageSender.new(bot: bot,
                        chat: message.chat,
                        text: "Non so cosa sia #{message.text}"
                        ).send
    end
  end

  #TODO: un/una dependin on meal type
  def choose_meal_and_notify_pietro(meal)
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Figo! Farò sapere a Pietro che vuoi #{meal}",
                      # hide_kb: true
                      ).send
    MessageSender.new(bot: bot,
                      chat: Telegram::Bot::Types::Chat.new(id: @pietro.chat_id),
                      text: "#{message.chat.first_name} vuole #{meal}",
                      # hide_kb: true
                      ).send
    Order.create(user: @user, user_name: message.chat.first_name, item: meal, price: MenuItem.find_by(name: meal).price)
  end

  def answer_with_orders
    orders = Order.where 'created_at > ?', Date.today.to_time

    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: orders_summary(orders),
                      parse_mode: 'Markdown'
                      ).send
  end

  # def ask_for_discounts
  #   MessageSender.new(bot: bot,
  #                     chat: message.chat,
  #                     text: "Quante tessere vuoi usare?",
  #                     force_reply: true
  #                     ).send
  # end

  # def send_price_per_person n_discounts
  #   orders = Order.where 'created_at > ?', Date.today.to_time
  #   total = orders.map(&:price).reduce(:+) - (6.0 * n_discounts)
  #
  #   orders.each do |o|
  #     MessageSender.new(bot: bot,
  #                       chat: o.user.id,
  #                       text: "Pietro ha ordinato! Gli devi #{total/orders.count}"
  #                       ).send
  #   end
  # end

  def display_keyboard_for food_list
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Ottima idea! Adesso scegli cosa vuoi mangiare e aspetta che qualcuno te lo vada a prendere",
                      answers: food_list
                      ).send
  end

  def go_to_delete_menu
    answer_with_delete_menu
    @user.update_attributes state: 'deleting'
  end

  def answer_with_delete_menu
    todays_order = Order.where('user_id = ? AND created_at > ?', @user.id, Date.today)
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Scegli quali elementi eliminare",
                      answers: todays_order.map {|o| "Elimina #{o.item}"} + ["Annulla"]
                      ).send
  end

  def remove_meal_from_order name
    order = Order.find_by('user_id = ? AND created_at > ? AND item = ?', @user.id, Date.today, name)
    order.destroy

    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Ok. Hai eliminato #{name} dal tuo ordine"
                      ).send
  end

  def answer_with_orostube_closed
    @user.update_attributes state: nil
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Oh no! Sembra che l'OroStube sia chiuso oggi!"
                      ).send
  end

  def answer_with_reset_message
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Ok, ora puoi ricominciare!"
                      ).send
  end

  def display_help
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: %{
                        Usa il comando /start per iniziare (come ai vecchi tempi)
                      }.gsub(/^[\s]+/, "")
                      ).send
  end

  def orders_summary orders
    if orders.any?
      total = orders.map(&:price).reduce(:+)
      %{
        #{orders.map.with_index {|o, i| "#{i+1}. *#{o.user_name}* vuole #{o.item}"}.join("\n")}
        -----
        *Totale:* #{total} €
      }.gsub(/^[\s]+/, "")
    else
      "Non ci sono ordini"
    end
  end
end
