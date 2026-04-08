# frozen_string_literal: true

module TelegramDotaStatsBot
  module StatsInfo
    def rank_to_medal(rank)
      return "Калибровка" if rank.nil? || rank.negative?

      case rank
      when 0..9
        "Рекрут"
      when 10..19
        "Страж"
      when 20..29
        "Рыцарь"
      when 30..39
        "Герой"
      when 40..49
        "Легенда"
      when 50..59
        "Властелин"
      when 60..79
        "Божество"
      else
        "Титан"
      end
    end
  end
end
