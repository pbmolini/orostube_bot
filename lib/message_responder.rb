require './models/user'
require './lib/message_sender'
require './lib/menu_builder'
require 'nokogiri'
require 'open-uri'
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

    case @user.state
    when /choosing_[#{MenuItem::CATEGORIES.join('|')}]/
      on /Indietro/ do
        answer_with_menu @user.state.gsub('choosing_','')
      end

      on /Ordina (.+)/ do |name|
        choose_meal_and_notify_pietro name
        @user.update_attributes state: nil
      end

      on /^(?!.*(Indietro|Ordina)).*$/ do
        answer_with_details
      end

      # choose_meal_and_notify_pietro message.text
      # @user.update_attributes state: nil
    else
      on /^\/(pizze|cucina|insalate)\s*$/ do |category|
        @user.update_attributes state: "choosing_#{category.to_s}"
        answer_with_menu category.to_sym
      end

      # For th Pros
      on /^\/pizza (.+)/ do |pizza|
        choose_meal_and_notify_pietro "\u{1f355} #{pizza.gsub(/[Pp]izza /, "")}"
      end

      on /^\/cucina (.+)/ do |cucina|
        choose_meal_and_notify_pietro "\u{1f372} #{cucina}"
      end

      on /^\/insalata (.+)/ do |salad|
        choose_meal_and_notify_pietro "\u{1f331} #{salad.gsub(/[Ii]nsalata /, "")}"
      end

      on /^\/help/ do
        display_help
      end
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

  def answer_with_menu category
    items = MenuBuilder.retrieve(category)
    names = items.map(&:name)
    names.any? ? display_keyboard_for(names) : answer_with_orostube_closed
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
                        answers: ['Indietro', "Ordina #{item.name}"]
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
  end

  def display_keyboard_for food_list
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Ottima idea! Adesso scegli cosa vuoi mangiare e aspetta che qualcuno te lo vada a prendere",
                      answers: food_list
                      ).send
  end

  def answer_with_orostube_closed
    @user.update_attributes state: nil
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: "Oh no! Sembra che l'OroStube sia chiuso oggi!"
                      ).send
  end

  def display_help
    MessageSender.new(bot: bot,
                      chat: message.chat,
                      text: %{
                        *Per vedere cosa c'è oggi:*
                        ----
                        /pizze per le pizze
                        /insalate per le insalate
                        /cucina per la cucina
                        ----
                      }.gsub(/^[\s]+/, ""),
                      parse_mode: 'Markdown'
                      ).send
  end
end
