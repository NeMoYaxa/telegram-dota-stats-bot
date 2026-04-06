# frozen_string_literal: true

require_relative "client"

module TelegramDotaStatsBot
  class Match
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
          }#{"   "}
        }#{"   "}
      GQL

      response = Client.query(query)

      response.body
    end

    def parse_match(match_id)
      json = fetch_match(match_id)

      return nil if json.nil? || json.empty?

      begin
        data = JSON.parse(json)

        puts "GraphQL ошибка: #{data["errors"]}" if data["errors"]

        match = data.dig("data", "match")

        puts "Матч c ID: #{match_id} не найден." if match.nil?

        {
          id: match["id"],
          didRadiantWin: match["didRadiantWin"],
          durationSeconds: match["durationSeconds"],
          startDateTime: match["startDateTime"],
          endDateTime: match["endDateTime"],
          lobbyType: match["lobbyType"],
          rank: match["rank"],
          regionId: match["regionId"]
        }
      rescue JSON::JSONError => e
        puts "Ошибка парсинга JSON: #{e.message}"
        nil
      end
    end
  end
end
