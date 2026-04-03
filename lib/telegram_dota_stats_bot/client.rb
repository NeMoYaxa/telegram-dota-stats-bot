# frozen_string_literal: true

require "dotenv/load"
require "httparty"
require "json"

module TelegramDotaStatsBot
  class Client
    STRATZ_GRAPHQL = "https://api.stratz.com/graphql"

    def self.query(gql)
      token = ENV.fetch("STRATZ_TOKEN", nil)

      puts "Ошибка: STRATZ_TOKEN не найден в .env файле." if token.nil?

      HTTParty.post(
        STRATZ_GRAPHQL,
        headers: {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        },
        body: { query: gql }.to_json
      )
    end
  end
end
