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
      on /^\/pizze/ do
        @user.update_attributes state: 'choosing_meal'
        answer_with_pizza_list(message)
      end

      on /^\/cucina\s*$/ do
        @user.update_attributes state: 'choosing_meal'
        answer_with_cucina_list(message)
      end

      on /^\/insalate/ do
        @user.update_attributes state: 'choosing_meal'
        answer_with_salad_list(message)
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

  def answer_with_pizza_list message
    pizzas = Nokogiri::HTML(open('http://www.orostube.it/products-list/4', 'User-Agent' => 'ruby')).css(".elenco-item")
    pizza_names = pizzas.map {|p| "\u{1f355} " + p.css("p").first.text.gsub(/\s+$/, "")}
    pizza_ingredients = pizzas.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    pizza_names.any? ? display_keyboard_for(pizza_names) : answer_with_orostube_closed
  end

  def answer_with_cucina_list message
    cucinas = Nokogiri::HTML(open('http://www.orostube.it/products-list/5', 'User-Agent' => 'ruby')).css(".elenco-item")
    cucina_names = cucinas.map {|p| "\u{1f372} " + p.css("p").first.text.gsub(/\s+$/, "")}
    cucina_ingredients = cucinas.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    cucina_names.any? ? display_keyboard_for(cucina_names) : answer_with_orostube_closed
  end

  def answer_with_salad_list message
    salads = Nokogiri::HTML(open('http://www.orostube.it/products-list/12', 'User-Agent' => 'ruby')).css(".elenco-item")
    salad_names = salads.map {|p| "\u{1f331} " + p.css("p").first.text.gsub(/\s+$/, "")}
    salad_ingredients = salads.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    salad_names.any? ? display_keyboard_for(salad_names) : answer_with_orostube_closed
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
                        Per vedere cosa c'è oggi:
                        ----
                        /pizze per le pizze
                        /insalate per le insalate
                        /cucina per la cucina
                        ----
                      }.gsub(/^[\s]+/, "")
                      ).send
  end
end
