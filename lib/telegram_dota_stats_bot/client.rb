# frozen_string_literal: true

require "dotenv/load"
require "httparty"
require "json"

module TelegramDotaStatsBot
  class Client
    STRATZ_GRAPHQL = "https://api.stratz.com/graphql"

    def self.query(gql)
      token = ENV.fetch("STRATZ_TOKEN", nil)

      response = HTTParty.post(
        STRATZ_GRAPHQL,
        headers: {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json",
          "User-Agent" => "TelegramDotaStatsBot/1.0"
        },
        body: { query: gql }.to_json,
        timeout: 60
      )

      return response if response.success? && response.body && !response.body.empty?

      puts "Ошибка Stratz API: #{response.code} - #{response.body}"
      nil
    rescue Net::OpenTimeout, Net::ReadTimeout
      puts "Ошибка: Превышено время ожидания Stratz API"
      nil
    rescue StandardError => e
      puts "Ошибка сети: #{e.message}"
      nil
    end
  end
end
