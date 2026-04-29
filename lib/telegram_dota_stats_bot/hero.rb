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
            stats(bracketBasicIds: [DIVINE_IMMORTAL], positionIds: [POSITION_#{position_id}]) {
              heroId
              winCount
              matchCount
            }
          }
          constants {
            heroes { id, displayName }
          }
        }
      GQL

      response = Client.query(query)
      return [] if response.nil? || response.body.nil? || response.body.empty?

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
            gameVersion { name }
          }
          heroStats {
            stats(heroIds: [#{hero_id}], bracketBasicIds: [DIVINE_IMMORTAL]) {
              winCount
              matchCount
            }
          }
        }
      GQL

      response = Client.query(query)
      return nil if response.nil? || response.body.nil? || response.body.empty?

      parse_hero_details(response.body, hero_id)
    end

    private

    def parse_recommended(json)
      data = JSON.parse(json)
      stats = data.dig("data", "heroStats", "stats") || []
      heroes_const = data.dig("data", "constants", "heroes") || []

      recommended = stats.map do |s|
        h = heroes_const.find { |hc| hc["id"] == s["heroId"] }
        next if h.nil?

        {
          name: h["displayName"],
          id: s["heroId"],
          win_rate: calculate_win_rate(s["matchCount"], s["winCount"])
        }
      end.compact

      recommended.sort_by { |h| -h[:win_rate] }.first(3)
    end

    def parse_hero_details(json, hero_id)
      data = JSON.parse(json)
      hero_c = data.dig("data", "constants", "hero")
      version = data.dig("data", "constants", "gameVersion", "name")
      stats_array = data.dig("data", "heroStats", "stats") || []
      hero_s = stats_array.first

      return nil if hero_c.nil? || hero_s.nil?

      {
        id: hero_id,
        name: hero_c["displayName"],
        patch: version || "Unknown",
        win_rate: calculate_win_rate(hero_s["matchCount"], hero_s["winCount"]),
        match_count: hero_s["matchCount"],
        image_url: "https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/#{hero_c["shortName"]}.png"
      }
    end
  end
end
