# frozen_string_literal: true

require "dotenv/load"
require "httparty"
require "json"
require_relative "client"
require_relative "stats_info"

module TelegramDotaStatsBot
  class Player
    include StatsInfo

    def fetch_player(steam_id)
      query = <<~GQL
        {
          player(steamAccountId: #{steam_id}) {
            steamAccount {
              id
              profileUri
              name
              isDotaPlusSubscriber
              seasonRank
            }
            matchCount
            winCount
          }
        }
      GQL

      response = Client.query(query)

      return nil if response.nil?

      response.body
    end

    def parse_player(steam_id)
      json = fetch_player(steam_id)

      return nil if json.nil? || json.empty?

      begin
        data = JSON.parse(json)

        if data["errors"]
          puts "GraphQL ошибка: #{data["errors"]}"
          return nil
        end

        steam_account = data.dig("data", "player", "steamAccount")

        if steam_account.nil?
          puts "Игрок с ID: #{steam_id} не найден."
          return nil
        end

        player_data = data.dig("data", "player")

        {
          id: steam_account["id"],
          profile_uri: steam_account["profileUri"],
          name: steam_account["name"],
          is_dota_plus_subscriber: steam_account["isDotaPlusSubscriber"],
          season_rank: rank_to_medal(steam_account["seasonRank"]),
          match_count: player_data["matchCount"] || 0,
          win_count: player_data["winCount"] || 0,
          win_rate: calculate_win_rate(player_data["matchCount"], player_data["winCount"])
        }
      rescue JSON::JSONError => e
        puts "Ошибка парсинга JSON: #{e.message}"
        nil
      end
    end

    private

    def calculate_win_rate(total, wins)
      return 0 if total.nil? || total.zero?

      ((wins.to_f / total) * 100).round(2)
    end
  end
end
