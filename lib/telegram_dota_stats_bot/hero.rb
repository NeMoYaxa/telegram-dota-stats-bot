# frozen_string_literal: true

require_relative "client"
require_relative "stats_info"

module TelegramDotaStatsBot
  class Hero
    include StatsInfo



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
          constants { heroes { id, displayName } }
        }
      GQL

      response = Client.query(query)
      return [] unless response

      parse_recommended(response.body)
    end


    def fetch_hero_details(hero_id)
      query = <<~GQL
        {
          constants {
            hero(id: #{hero_id}) { displayName, shortName }
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
      return nil unless response

      parse_hero_details(response.body, hero_id)
    end


    def fetch_all_heroes
      query = <<~GQL
        {
          constants {
            heroes {
              id
              displayName
              shortName
            }
          }
        }
      GQL

      response = Client.query(query)
      return [] unless response

      parse_all_heroes(response.body)
    end


    def fetch_hero_build(hero_id)
      query = <<~GQL
        {
          constants {
            hero(id: #{hero_id}) {
              displayName
              shortName
            }
            items {
              id
              displayName
              shortName
            }
          }
          heroStats {
            itemFullPurchase(heroId: #{hero_id}) {
              itemId
              time
              winsAverage
            }
          }
        }
      GQL

      response = Client.query(query)
      return nil unless response

      parse_hero_build(response.body)
    end


    private

    def parse_recommended(json)
      data = JSON.parse(json)
      stats = data.dig("data", "heroStats", "stats") || []
      heroes_const = data.dig("data", "constants", "heroes") || []

      recommended = stats.map do |s|
        h = heroes_const.find { |hc| hc["id"] == s["heroId"] }
        next if h.nil?
        next if (s["matchCount"] || 0) < 5000

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

      current_patch = "7.41b"

      hero_c = data.dig("data", "constants", "hero")
      stats_array = data.dig("data", "heroStats", "stats") || []
      hero_s = stats_array.first

      return nil if hero_c.nil? || hero_s.nil?

      {
        id: hero_id,
        name: hero_c["displayName"],
        patch: current_patch,
        win_rate: calculate_win_rate(hero_s["matchCount"], hero_s["winCount"]),
        match_count: hero_s["matchCount"],
        rank_text: "💠 Divine / Immortal",
        image_url: "https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/#{hero_c["shortName"]}.png"
      }
    end

    def parse_all_heroes(json)
      data = JSON.parse(json)
      heroes = data.dig("data", "constants", "heroes") || []

      heroes.map do |hero|
        {
          id: hero["id"],
          name: hero["displayName"],
          short_name: hero["shortName"]
        }
      end.sort_by { |h| h[:name] }
    end

    def parse_hero_build(json)
      data = JSON.parse(json)

      hero = data.dig("data", "constants", "hero")
      items = data.dig("data", "constants", "items") || []
      purchases = data.dig("data", "heroStats", "itemFullPurchase") || []

      return nil if hero.nil?

      items_map = {}
      items.each do |item|
        items_map[item["id"]] = {
          name: item["displayName"],
          short_name: item["shortName"]
        }
      end

      best_items = parse_best_items_by_time_from_purchases(purchases, items_map)

      {
        name: hero["displayName"],
        short_name: hero["shortName"],
        best_items: best_items
      }
    end

    def parse_best_items_by_time_from_purchases(purchases, items_map = {})
      intervals = [
        { name: "0-10", min: 0, max: 10 },
        { name: "11-20", min: 11, max: 20 },
        { name: "21-30", min: 21, max: 30 },
        { name: "31-40", min: 31, max: 40 },
        { name: "41-50", min: 41, max: 50 },
        { name: "51-60", min: 51, max: 60 }
      ]

      results = []
      used_items = []

      intervals.each do |interval|
        interval_purchases = purchases.select do |p|
          p["time"] >= interval[:min] && p["time"] <= interval[:max]
        end

        next if interval_purchases.empty?

        best = interval_purchases
                 .reject { |p| used_items.include?(p["itemId"]) }
                 .max_by { |p| p["winsAverage"] }

        if best.nil?
          best = interval_purchases.max_by { |p| p["winsAverage"] }
        end

        used_items << best["itemId"]

        item_name = items_map[best["itemId"]]&.[](:name) || "Unknown Item (#{best["itemId"]})"

        results << {
          interval: interval[:name],
          item_id: best["itemId"],
          item_name: item_name,
          time: best["time"],
          winrate: (best["winsAverage"] * 100).round(2)
        }
      end

      results
    end
  end
end