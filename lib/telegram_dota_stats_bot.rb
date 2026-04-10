# frozen_string_literal: true

require "telegram/bot"
require "dotenv/load"
require "logger"
require_relative "telegram_dota_stats_bot/version"
require_relative "telegram_dota_stats_bot/view"
require_relative "telegram_dota_stats_bot/player"
require_relative "telegram_dota_stats_bot/match"

module TelegramDotaStatsBot
  class Error < StandardError; end

  @logger = Logger.new("bot.log", 1, 10 * 1024 * 1024)

  @logger.formatter = proc do |severity, datetime, _progname, msg|
    "[#{datetime.strftime("%Y-%m-%d %H:%M:%S")}] #{severity}: #{msg}\n"
  end

  def self.log
    @logger
  end

  def self.run
    token = ENV.fetch("TELEGRAM_BOT_TOKEN", nil)

    if token.nil?
      log.error("Ошибка: TELEGRAM_BOT_TOKEN не найден в .env файле")
      puts "Ошибка: TELEGRAM_BOT_TOKEN не найден в .env файле"
    end

    log.info("Бот запущен")
    puts "Бот запущен"

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        user_info = "#{message.from.id} (@#{message.from.username})"
        @states ||= {}

        case message.text
        when "/start"
          log.info("#{user_info} запустил бота")

          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Приветствуем тебя в DotaStats.",
            reply_markup: View.main_menu
          )
        when "👤 Посмотреть профиль игрока"
          log.info("#{user_info} выбрал '👤 Посмотреть профиль игрока'")

          @states[message.from.id] = :waiting_player_id

          log.debug("#{user_info} перешел в состояние :waiting_player_id")

          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Введите id игрока:"
          )
        when "📊 Посмотреть статистику матча"
          log.info("#{user_info} выбрал '📊 Посмотреть статистику матча'")

          @states[message.from.id] = :waiting_match_id

          log.debug("#{user_info} перешел в состояние :waiting_match_id")

          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Введите id матча:"
          )
        else
          case @states[message.from.id]
          when :waiting_player_id
            log.info("Получен ввод ID игрока от #{user_info}: #{message.text}")

            player_request(bot, message, user_info)

            log.info("Состояние для #{user_info} сброшено в nil")

            @states[message.from.id] = nil
          when :waiting_match_id
            log.info("Получен ввод ID матча от #{user_info}: #{message.text}")

            match_request(bot, message, user_info)

            log.info("Состояние для #{user_info} сброшено в nil")

            @states[message.from.id] = nil
          end
        end
      end
    end
  rescue Interrupt
    log.info("Бот остановлен")
    puts "Бот остановлен"
  end

  def self.player_request(bot, message, user_info)
    log.info("Парсинг игрока #{message.text} для #{user_info}")

    player_data = Player.new.parse_player(message.text)

    if player_data.nil?
      log.warn("Игрок #{message.text} не найден для #{user_info}")

      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Игрок с id <code>#{message.text}</code> не найден.",
        parse_mode: "HTML",
        reply_markup: View.main_menu
      )
    else
      log.info("Игрок #{message.text} успешно получен для #{user_info}")
      log.debug("Данные игрока: #{player_data.inspect}")

      bot.api.send_message(
        chat_id: message.chat.id,
        text: View.render_player_stats(player_data),
        disable_web_page_preview: true,
        parse_mode: "HTML",
        reply_markup: View.main_menu
      )
    end
  end

  def self.match_request(bot, message, user_info)
    log.info("Парсинг матча #{message.text} для #{user_info}")

    match_data = Match.new.parse_match(message.text)

    if match_data.nil?
      log.warn("Матч #{message.text} не найден для #{user_info}")

      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Матч с id <code>#{message.text}</code> не найден.",
        parse_mode: "HTML",
        reply_markup: View.main_menu
      )
    else
      log.info("Матч #{message.text} успешно получен для #{user_info}")
      log.debug("Данные матча: #{match_data.inspect}")

      bot.api.send_message(
        chat_id: message.chat.id,
        text: View.render_match_stats(match_data),
        parse_mode: "HTML",
        reply_markup: View.main_menu
      )
    end
  end
end
