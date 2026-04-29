# frozen_string_literal: true

require_relative "test_helper"

class TestClient < Minitest::Test
  def setup
    @client = TelegramDotaStatsBot::Client
    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
  end

  def test_query_returns_response
    fake_gql = <<~GQL
      {
        player(steamAccountId: 1234567890) {
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

    fake_json = <<~JSON
      {
        "data": {
          "player": {
            "steamAccount": {
              "id": 1234567890,
              "profileUri": "https://steamcommunity.com/id/1356236241/",
              "name": "Vladimir",
              "isDotaPlusSubscriber": false,
              "seasonRank": 75
            },
            "matchCount": 4124,
            "winCount": 2225
          }
        }
      } 
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_equal fake_json.strip, @client.query(fake_gql).body.strip
  end
end
