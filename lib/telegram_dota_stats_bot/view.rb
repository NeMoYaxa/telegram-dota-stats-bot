# frozen_string_literal: true

module TelegramDotaStatsBot
  class View
    def self.button(text)
      Telegram::Bot::Types::KeyboardButton.new(text: text)
    end

    def self.main_menu
      kb = [
        [button("👤 Посмотреть профиль игрока")],
        [button("📊 Посмотреть статистику матча")]
      ]

      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: kb,
        resize_keyboard: true,
        one_time_keyboard: true
      )
    end

    def self.render_player_stats(data)
      [
        "🔑 <b>ID:</b> <code>#{data[:id]}</code>",
        "👤 <b>Игрок:</b> <a href='#{data[:profile_uri]}'>#{data[:name]}</a>",
        "🏆 <b>Ранг:</b> #{data[:season_rank]}",
        "🎮 <b>Всего игр:</b> #{data[:match_count]}",
        "📈 <b>Винрейт:</b> #{data[:win_rate]}%",
        "✨ <b>Dota Plus:</b> #{data[:is_dota_plus_subscriber] ? "Есть" : "Нет"}"
      ].join("\n")
    end
  end
end
