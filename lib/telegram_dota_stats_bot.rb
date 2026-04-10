# frozen_string_literal: true

require "telegram/bot"
require "dotenv/load"
require_relative "telegram_dota_stats_bot/version"
require_relative "telegram_dota_stats_bot/view"
require_relative "telegram_dota_stats_bot/player"
require_relative "telegram_dota_stats_bot/match"

module TelegramDotaStatsBot
  class Error < StandardError; end

  def self.run
    token = ENV.fetch("TELEGRAM_BOT_TOKEN", nil)

    puts "Ошибка: TELEGRAM_BOT_TOKEN не найден в .env файле" if token.nil?

    puts "Бот запущен."

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        @states ||= {}

        case message.text
        when "/start"
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Приветствуем тебя в DotaStats.",
            reply_markup: View.main_menu
          )
        when "👤 Посмотреть профиль игрока"
          @states[message.from.id] = :waiting_player_id

          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Введите id игрока:"
          )
        when "📊 Посмотреть статистику матча"
          @states[message.from.id] = :waiting_match_id

          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Введите id матча:"
          )
        else
          case @states[message.from.id]
          when :waiting_player_id
            player_data = Player.new.parse_player(message.text)

            puts "DEBUG: player_data is #{player_data.inspect}"

            bot.api.send_message(
              chat_id: message.chat.id,
              text: View.render_player_stats(player_data),
              disable_web_page_preview: true,
              parse_mode: "HTML"
            )

            @states[message.from.id] = nil
          when :waiting_match_id

            @states[message.from.id] = nil
          end
        end
      end
    end
  end
end
