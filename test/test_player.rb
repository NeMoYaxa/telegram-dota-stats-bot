# frozen_string_literal: true

require "test_helper"
WebMock.allow_net_connect!

class TestPlayer < Minitest::Test
  def setup
    @player = TelegramDotaStatsBot::Player.new
    @url = TelegramDotaStatsBot::Player::STRATZ_GRAPHQL
    @steam_id = 1234567890

    ENV["STRATZ_TOKEN"] = "test_token_123"
  end

  def test_fetch_player_returns_json_200
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

    assert_equal fake_json, @player.fetch_player(@steam_id)
  end

  def test_parse_player_return_correct_hash
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

    player_data = @player.parse_player(@steam_id)

    expected_info = {
      id: 1234567890,
      profile_uri: "https://steamcommunity.com/id/1356236241/",
      name: "Vladimir",
      is_dota_plus_subscriber: false,
      season_rank: "Божество",
      match_count: 4124,
      win_count: 2225,
      win_rate: 53.95
    }

    assert_equal expected_info, player_data
  end
end
