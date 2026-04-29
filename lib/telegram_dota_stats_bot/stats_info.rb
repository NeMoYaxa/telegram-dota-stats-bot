# frozen_string_literal: true

require_relative "client"

module TelegramDotaStatsBot
  module StatsInfo
    def calculate_win_rate(total, wins)
      return 0 if total.nil? || total.zero?

      ((wins.to_f / total) * 100).round(2)
    end

    def match_duration_to_string_time(seconds)
      return nil if seconds.nil?

      "#{seconds / 60}мин. #{seconds % 60}сек."
    end

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

    def region_id_to_client_name(id)
      return "Unspecified" if id.nil? || id.zero?
      return "Taiwan" if id == 37
      return "Argentina" if id == 38

      regions = parse_regions
      regions[id]
    end

    private

    def fetch_regions
      query = <<~GQL
        {
          constants {
            regions {
              id
              name
              clientName
            }
          }
        }
      GQL

      response = Client.query(query)

      response.body
    end

    def parse_regions
      json = fetch_regions

      return nil if json.nil? || json.empty?

      begin
        data = JSON.parse(json)

        if data["errors"]
          puts "GraphQL ошибка: #{data["errors"]}"
          return nil
        end

        regions = data.dig("data", "constants", "regions")

        if regions.nil?
          puts "Ошибка, регионы не найдены."
          return nil
        end

        regions.to_h do |region|
          [region["id"], region["clientName"]]
        end
      rescue JSON::JSONError => e
        puts "Ошибка парсинга JSON: #{e.message}"
        nil
      end
    end
  end
end
