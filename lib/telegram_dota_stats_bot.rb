# frozen_string_literal: true

require "telegram/bot"
require "dotenv/load"
require_relative "telegram_dota_stats_bot/version"
require_relative "telegram_dota_stats_bot/player"

module TelegramDotaStatsBot
  class Error < StandardError; end

  def self.run
    token = ENV.fetch("TELEGRAM_BOT_TOKEN", nil)

    puts "Ошибка: TELEGRAM_BOT_TOKEN не найден в .env файле" if token.nil?

    puts "Бот запущен."

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        case message.text
        when "/start"
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Приветствуем тебя в DotaStats."
          )
        end
      end
    end
  end
end
