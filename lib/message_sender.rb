require './lib/reply_markup_formatter'
require './lib/app_configurator'

class MessageSender
  attr_reader :bot
  attr_reader :text
  attr_reader :chat
  attr_reader :answers
  attr_reader :reply_to_message
  attr_reader :logger

  def initialize(options)
    @bot = options[:bot]
    @text = options[:text]
    @chat = options[:chat]
    @answers = options[:answers]
    @reply_to_message_id = options[:reply_to_message_id]
    @logger = AppConfigurator.new.get_logger
  end

  def send
    params = { chat_id: chat.id, text: text }
    params[:reply_markup] = reply_markup if reply_markup
    params[:reply_to_message_id] = @reply_to_message_id if @reply_to_message_id

    resp = bot.api.send_message(params)

    logger.debug "resp: #{resp}"
    logger.debug "sending '#{text}' to #{chat.username}"
  end

  private

  def reply_markup
    if answers
      ReplyMarkupFormatter.new(answers).get_markup
    end
  end

end
