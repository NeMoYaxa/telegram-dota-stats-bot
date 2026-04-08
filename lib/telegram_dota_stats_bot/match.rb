# frozen_string_literal: true

require_relative "client"
require_relative "stats_info"

module TelegramDotaStatsBot
  class Match
    include StatsInfo

    def fetch_match(match_id)
      query = <<~GQL
        {
          match(id: #{match_id}) {
            id
            didRadiantWin
            durationSeconds
            startDateTime
            endDateTime
            lobbyType
            rank
            regionId
          }
        }
      GQL

      response = Client.query(query)

      response.body
    end

    def parse_match(match_id)
      json = fetch_match(match_id)

      return nil if json.nil? || json.empty?

      begin
        data = JSON.parse(json)

        if data["errors"]
          puts "GraphQL ошибка: #{data["errors"]}"
          return nil
        end

        match = data.dig("data", "match")

        if match.nil?
          puts "Игрок с ID: #{match_id} не найден."
          return nil
        end

        {
          id: match["id"],
          didRadiantWin: match["didRadiantWin"],
          durationSeconds: match_duration_to_string_time(match["durationSeconds"]),
          startDateTime: Time.at(match["startDateTime"]).to_s,
          endDateTime: Time.at(match["endDateTime"]).to_s,
          lobbyType: match["lobbyType"],
          rank: rank_to_medal(match["rank"]),
          regionId: region_id_to_client_name(match["regionId"])
        }
      rescue JSON::JSONError => e
        puts "Ошибка парсинга JSON: #{e.message}"
        nil
      end
    end
  end
end
