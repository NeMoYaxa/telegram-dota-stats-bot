# frozen_string_literal: true

require "test_helper"

class TestPlayer < Minitest::Test
  def setup
    @player = TelegramDotaStatsBot::Player.new
    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
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

  def test_parse_player_returns_correct_hash
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

  def test_parse_player_nil_hash_returns_nil
    fake_json = nil

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_player_empty_hash_returns_nil
    fake_json = ""

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_player_graphql_errors_returns_nil
    fake_json = <<~JSON
      {
        "errors": [
          {
            "message": "Some GraphQL error"
          }
        ]
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_player_graphql_no_player_returns_nil
    fake_json = <<~JSON
      {
         "message": "Some GraphQL error"
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_player_error_json_returns_nil
    fake_json = "abba"

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_calculate_win_rate_total_nil
    total_nil = @player.send(:calculate_win_rate, nil, nil)

    assert_equal 0, total_nil
  end

  def test_calculate_win_rate_total_zero
    total_zero = @player.send(:calculate_win_rate, 0, 0)

    assert_equal 0, total_zero
  end

  def test_calculate_win_rate_normal
    win_rate = @player.send(:calculate_win_rate, 100, 55)

    assert_equal 55.0, win_rate
  end

  def test_fetch_last_matches_returns_json_200
    fake_json = <<~JSON
      {
        "data": {
          "player": {
            "matches": [
              {"id":8767026994,"didRadiantWin":false,"durationSeconds":2634,"startDateTime":1775911947,"endDateTime":1775914581,"lobbyType":"RANKED","rank":80,"regionId":8},
              {"id":8766963195,"didRadiantWin":true,"durationSeconds":2213,"startDateTime":1775909348,"endDateTime":1775911561,"lobbyType":"RANKED","rank":74,"regionId":8},
              {"id":8766883730,"didRadiantWin":true,"durationSeconds":3116,"startDateTime":1775905707,"endDateTime":1775908823,"lobbyType":"RANKED","rank":74,"regionId":8}
            ]
          }
        }
      } 
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_equal fake_json, @player.fetch_last_matches(@steam_id, 3)
  end

  def test_parse_matches_returns_correct_hash
    fake_regions_json = <<~JSON
      {
        "data": {
          "constants": {
            "regions": [
              { "id": 8,  "name": "Stockholm", "clientName": "Russia" }
            ]
          }
        }
      }
    JSON

    stub_request(:post, @url).with(body: /constants/).to_return(status: 200, body: fake_regions_json)

    fake_json = <<~JSON
      {
        "data": {
          "player": {
            "matches": [
              {"id":8767026994,"didRadiantWin":false,"durationSeconds":2634,"startDateTime":1775911947,"endDateTime":1775914581,"lobbyType":"RANKED","rank":80,"regionId":8},
              {"id":8766963195,"didRadiantWin":true,"durationSeconds":2213,"startDateTime":1775909348,"endDateTime":1775911561,"lobbyType":"RANKED","rank":74,"regionId":8}
            ]
          }
        }
      } 
    JSON

    stub_request(:post, @url).with(body: /match/).to_return(status: 200, body: fake_json)

    matches_data = @player.parse_last_matches(@steam_id, 2)

    expected_info = [
      {
        id: 8767026994,
        didRadiantWin: false,
        durationSeconds: "43мин. 54сек.",
        startDateTime: "2026-04-11 15:52:27 +0300",
        endDateTime: "2026-04-11 16:36:21 +0300",
        lobbyType: "RANKED",
        rank: "Титан",
        regionId: "Russia"
      },
      {
        id: 8766963195,
        didRadiantWin: true,
        durationSeconds: "36мин. 53сек.",
        startDateTime: "2026-04-11 15:09:08 +0300",
        endDateTime: "2026-04-11 15:46:01 +0300",
        lobbyType: "RANKED",
        rank: "Божество",
        regionId: "Russia"
      }
    ]

    assert_equal expected_info, matches_data
  end

  def test_parse_matches_nil_hash_returns_nil
    fake_json = nil

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_last_matches(@steam_id, 10)
  end

  def test_parse_matches_empty_hash_returns_nil
    fake_json = ""

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_last_matches(@steam_id, 10)
  end

  def test_parse_matches_graphql_errors_returns_nil
    fake_json = <<~JSON
      {
        "errors": [
          {
            "message": "Some GraphQL error"
          }
        ]
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_last_matches(@steam_id, 10)
  end

  def test_parse_matches_graphql_no_player_returns_nil
    fake_json = <<~JSON
      {
         "message": "Some GraphQL error"
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_last_matches(@steam_id, 10)
  end

  def test_parse_matches_error_json_returns_nil
    fake_json = "abba"

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_last_matches(@steam_id, 10)
  end
end
