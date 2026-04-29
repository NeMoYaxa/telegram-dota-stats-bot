# frozen_string_literal: true

require_relative "client"
require_relative "stats_info"

module TelegramDotaStatsBot
  class Hero
    include StatsInfo

    POSITIONS = {
      1 => "Safelane",
      2 => "Midlane",
      3 => "Offlane",
      4 => "Soft Support",
      5 => "Hard Support"
    }.freeze

    def fetch_recommended(position_id)
      query = <<~GQL
        {
          heroStats {
            stats(bracketIds: [DIVINE_IMMORTAL], positionIds: [POSITION_#{position_id}]) {
              heroId
              winGameCount
              matchCount
            }
          }
          constants {
            heroes { id, displayName }
          }
        }
      GQL

      response = Client.query(query)
      parse_recommended(response.body)
    end

    def fetch_hero_details(hero_id)
      query = <<~GQL
        {
          constants {
            hero(id: #{hero_id}) {
              displayName
              shortName
            }
          }
          heroStats {
            hero(id: #{hero_id}) {
              winGameCount
              matchCount
              itemBootPurchase { itemId }
            }
          }
        }
      GQL

      response = Client.query(query)
      parse_hero_details(response.body)
    end

    private

    def parse_recommended(json)
      data = JSON.parse(json)
      stats = data.dig("data", "heroStats", "stats") || []
      heroes_const = data.dig("data", "constants", "heroes") || []

      recommended = stats.map do |s|
        h = heroes_const.find { |hc| hc["id"] == s["heroId"] }
        {
          name: h["displayName"],
          id: s["heroId"],
          win_rate: calculate_win_rate(s["matchCount"], s["winGameCount"])
        }
      end

      recommended.sort_by { |h| -h[:win_rate] }.first(3)
    end

    def parse_hero_details(json)
      data = JSON.parse(json)
      hero_c = data.dig("data", "constants", "hero")
      hero_s = data.dig("data", "heroStats", "hero")

      {
        name: hero_c["displayName"],
        icon_url: "https://cdn.stratz.com/images/dota2/heroes/#{hero_c["shortName"]}_horiz.png",
        win_rate: calculate_win_rate(hero_s["matchCount"], hero_s["winGameCount"]),
        suggested_boots_id: hero_s.dig("itemBootPurchase", 0, "itemId")
      }
    end
  end
end
