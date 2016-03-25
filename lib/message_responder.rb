require './models/user'
require './lib/message_sender'
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
    when 'choosing_meal'
      choose_meal_and_notify_pietro message.text
      @user.update_attributes state: nil
    else
      on /\/pizze/ do
        answer_with_pizza_list(message)
        @user.update_attributes state: 'choosing_meal'
      end

      on /\/paste/ do
        answer_with_pasta_list(message)
        @user.update_attributes state: 'choosing_meal'
      end

      on /\/insalate/ do
        answer_with_salad_list(message)
        @user.update_attributes state: 'choosing_meal'
      end

      on /\/pizza (.+)/ do |pizza|
        choose_meal_and_notify_pietro pizza.gsub(/[Pp]izza /, "")
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

  def answer_with_pizza_list message
    pizzas = Nokogiri::HTML(open('http://www.orostube.it/products-list/4', 'User-Agent' => 'ruby')).css(".elenco-item")
    pizza_names = pizzas.map {|p| "\u{1f355} " + p.css("p").first.text.gsub(/\s+$/, "")}
    pizza_ingredients = pizzas.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    display_keyboard_for pizza_names
  end

  def answer_with_pasta_list message
    pastas = Nokogiri::HTML(open('http://www.orostube.it/products-list/5', 'User-Agent' => 'ruby')).css(".elenco-item")
    pasta_names = pastas.map {|p| "\u{1f372} " + p.css("p").first.text.gsub(/\s+$/, "")}
    pasta_ingredients = pastas.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    display_keyboard_for pasta_names
  end

  def answer_with_salad_list message
    salads = Nokogiri::HTML(open('http://www.orostube.it/products-list/12', 'User-Agent' => 'ruby')).css(".elenco-item")
    salad_names = salads.map {|p| "\u{1f331} " + p.css("p").first.text.gsub(/\s+$/, "")}
    salad_ingredients = salads.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    display_keyboard_for salad_names
  end

  #TODO: un/una dependin on meal type
  def choose_meal_and_notify_pietro(meal)
    MessageSender.new(bot: bot, chat: message.chat, text: "Figo! Farò sapere a Pietro che vuoi una #{meal}").send
    MessageSender.new(bot: bot, chat: Telegram::Bot::Types::Chat.new(id: @pietro.chat_id), text: "#{message.chat.first_name} vuole #{meal}").send
  end

  def display_keyboard_for food_list
    MessageSender.new(bot: bot,
                      chat: message.chat, text: "Ottima idea! Adesso scegli cosa vuoi mangiare e aspetta che qualcuno te lo vada a prendere",
                      answers: food_list
                      ).send
  end
end
