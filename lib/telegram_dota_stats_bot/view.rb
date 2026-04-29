# frozen_string_literal: true

module TelegramDotaStatsBot
  class View
    def self.button(text)
      Telegram::Bot::Types::KeyboardButton.new(text: text)
    end

    def self.main_menu
      kb = [
        [button("👤 Посмотреть профиль игрока")],
        [button("📊 Посмотреть статистику матча")],
        [button("🦸 Выбор героя (Топ по позициям)")]
      ]

      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: kb,
        resize_keyboard: true,
        one_time_keyboard: true
      )
    end

    def self.render_player_stats(player_data)
      line = "➖➖➖➖➖➖➖➖➖➖➖➖"

      [
        "📝 Данные об аккаунте",
        line,
        "🔑 <b>ID:</b> <code>#{player_data[:id]}</code>",
        "👤 <b>Игрок:</b> <a href='#{player_data[:profile_uri]}'>#{player_data[:name]}</a>",
        "🏆 <b>Ранг:</b> #{player_data[:season_rank]}",
        "🎮 <b>Всего игр:</b> #{player_data[:match_count]}",
        "📈 <b>Винрейт:</b> #{player_data[:win_rate]}%",
        "✨ <b>Dota Plus:</b> #{player_data[:is_dota_plus_subscriber] ? "Есть" : "Нет"}"
      ].join("\n")
    end

    def self.render_match_stats(match_data)
      line = "➖➖➖➖➖➖➖➖➖➖➖➖"
      win_status = match_data[:didRadiantWin] ? "🟢 <b>Победа Radiant</b>" : "🔴 <b>Победа Dire</b>"

      [
        "📊 <b>Информация о матче</b>",
        line,
        "⚔️ <b>Match ID:</b> <code>#{match_data[:id]}</code>",
        win_status,
        "⏳ <b>Длительность:</b> #{match_data[:durationSeconds]}",
        "🏆 <b>Средний ранг:</b> #{match_data[:rank]}",
        "🌍 <b>Регион:</b> #{match_data[:regionId]}",
        "🎮 <b>Тип лобби:</b> #{match_data[:lobbyType]}",
        line,
        "📅 <b>Начало:</b> #{match_data[:startDateTime]}",
        "🏁 <b>Конец:</b>  #{match_data[:endDateTime]}"
      ].join("\n")
    end

    def self.render_hero_stats(hero_data)
      return "⚠️ Ошибка: данные героя не найдены." if hero_data.nil?

      [
        "<a href='#{hero_data[:image_url]}'>&#8205;</a>",
        "🦸 <b>#{hero_data[:name]}</b>",
        "📅 <b>Патч:</b> <code>#{hero_data[:patch]}</code>",
        "➖➖➖➖➖➖➖➖➖➖➖➖",
        "🏆 <b>Winrate:</b> <code>#{hero_data[:win_rate]}%</code>",
        "🎮 <b>Матчей:</b> <code>#{hero_data[:match_count]}</code>",
        "🏅 <b>Ранг:</b> 💠 Divine / Immortal",
        "➖➖➖➖➖➖➖➖➖➖➖➖",
        "🔗 <a href='https://stratz.com/heroes/#{hero_data[:id]}'>Stratz Profile</a>"
      ].join("\n")
    end

    def self.positions_menu
      buttons = (1..5).map do |i|
        Telegram::Bot::Types::KeyboardButton.new(text: "Позиция #{i}")
      end
      keyboard_rows = buttons.each_slice(2).to_a
      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: keyboard_rows,
        resize_keyboard: true,
        one_time_keyboard: true
      )
    end
  end
end
