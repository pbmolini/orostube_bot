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
    when 'choosing_pizza'
      choose_pizza_and_notify_pietro message.text.gsub(/[Pp]izza /, "")
      @user.update_attributes state: nil
    else
      if message.text == "/pizze"
        answer_with_pizza_list(message)
        @user.update_attributes state: 'choosing_pizza'
      end
      match = /\/pizza (.+)/.match(message.text)
      if match.present?
        choose_pizza_and_notify_pietro match.to_a[1].gsub(/[Pp]izza /, "")
      end
    end

  end

  private

  def answer_with_pizza_list message
    pizzas = Nokogiri::HTML(open('http://www.orostube.it/products-list/4', 'User-Agent' => 'ruby')).css(".elenco-item")
    @pizza_names = pizzas.map {|p| p.css("p").first.text.gsub(/\s+$/, "")}
    pizza_ingredients = pizzas.map {|p| p.css("p").last.text.gsub(/[\t\n]/, "").gsub(/\s+$/, "")}
    MessageSender.new(bot: bot,
                      chat: message.chat, text: "Pizze scaricate! Scegli la tua pizza e aspetta che qualcuno te la vada a prendere",
                      answers: @pizza_names
                      ).send
  end

  def choose_pizza_and_notify_pietro(pizza)
    MessageSender.new(bot: bot, chat: message.chat, text: "Figo! Farò sapere a Pietro che vuoi una pizza #{pizza}").send
    MessageSender.new(bot: bot, chat: Telegram::Bot::Types::Chat.new(id: @pietro.chat_id), text: "#{message.chat.first_name} vuole una pizza #{pizza}").send
  end
end
