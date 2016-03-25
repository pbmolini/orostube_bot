class ReplyMarkupFormatter
  attr_reader :array

  def initialize(array, options={})
    @array = array
    # @slices = options[:slices].present? ? options[:slices] : 1
  end

  def get_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: array.each_slice(2).to_a, one_time_keyboard: true)
  end

  def get_hide_keyboard
    Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
  end
end
