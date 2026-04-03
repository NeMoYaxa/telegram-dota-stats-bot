# frozen_string_literal: true

require "test_helper"
WebMock.allow_net_connect!

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

  def test_parse_rates_nil_hash_returns_nil
    fake_json = nil

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_rates_empty_hash_returns_nil
    fake_json = ""

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_rates_graphql_errors_returns_nil
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

  def test_parse_rates_graphql_no_player_returns_nil
    fake_json = <<~JSON
      {
         "message": "Some GraphQL error"
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_parse_rates_error_json_returns_nil
    fake_json = "abba"

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @player.parse_player(@steam_id)
  end

  def test_rank_to_medal_nil
    medal_nil = @player.send(:rank_to_medal, nil)

    assert_equal "Калибровка", medal_nil
  end

  def test_rank_to_medal_negative
    medal_nil = @player.send(:rank_to_medal, -1)

    assert_equal "Калибровка", medal_nil
  end

  def test_rank_to_medal_herald
    medal_herald = @player.send(:rank_to_medal, 1)

    assert_equal "Рекрут", medal_herald
  end

  def test_rank_to_medal_guardian
    medal_guardian = @player.send(:rank_to_medal, 11)

    assert_equal "Страж", medal_guardian
  end

  def test_rank_to_medal_crusader
    medal_crusader = @player.send(:rank_to_medal, 22)

    assert_equal "Рыцарь", medal_crusader
  end

  def test_rank_to_medal_archon
    medal_archon = @player.send(:rank_to_medal, 33)

    assert_equal "Герой", medal_archon
  end

  def test_rank_to_medal_legend
    medal_legend = @player.send(:rank_to_medal, 44)

    assert_equal "Легенда", medal_legend
  end

  def test_rank_to_medal_ancient
    medal_ancient = @player.send(:rank_to_medal, 55)

    assert_equal "Властелин", medal_ancient
  end

  def test_rank_to_medal_divine
    medal_divine = @player.send(:rank_to_medal, 76)

    assert_equal "Божество", medal_divine
  end

  def test_rank_to_medal_immortal
    medal_immortal = @player.send(:rank_to_medal, 80)

    assert_equal "Титан", medal_immortal
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
end
