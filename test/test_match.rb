# frozen_string_literal: true

require "test_helper"
WebMock.allow_net_connect!

class TestMatch < Minitest::Test
  def setup
    @match = TelegramDotaStatsBot::Match.new
    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
    @match_id = 1234567890
  end

  def test_fetch_match_returns_json_200
    fake_json = <<~JSON
      {
        "data": {
          "match": {
            "id": 1234567890,
            "didRadiantWin": true,
            "durationSeconds": 1234,
            "startDateTime": 10000,
            "endDateTime": 11234,
            "lobbyType": "RANKED",
            "rank": 80,
            "regionId": 8
          }
        }
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body:fake_json)

    assert_equal fake_json, @match.fetch_match(@match_id)
  end

  def test_parse_match_returns_correct_hash
    fake_json = <<~JSON
      {
        "data": {
          "match": {
            "id": 1234567890,
            "didRadiantWin": true,
            "durationSeconds": 1234,
            "startDateTime": 10000,
            "endDateTime": 11234,
            "lobbyType": "RANKED",
            "rank": 80,
            "regionId": 8
          }
        }
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    match_data = @match.parse_match(@match_id)

    expected_data = {
      id: 1234567890,
      didRadiantWin: true,
      durationSeconds: 1234,
      startDateTime: 10000,
      endDateTime: 11234,
      lobbyType: "RANKED",
      rank: "Титан",
      regionId: 8
    }

    assert_equal expected_data, match_data
  end

  def test_parse_match_nil_hash_returns_nil
    fake_json = nil

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @match.parse_match(@match_id)
  end

  def test_parse_match_empty_hash_returns_nil
    fake_json = ""

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @match.parse_match(@match_id)
  end

  def test_parse_match_graphql_errors_returns_nil
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

    assert_nil @match.parse_match(@match_id)
  end

  def test_parse_match_graphql_no_match_returns_nil
    fake_json = <<~JSON
      {
         "message": "Some GraphQL error"
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @match.parse_match(@match_id)
  end

  def test_parse_match_error_json_returns_nil
    fake_json = "abba"

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil @match.parse_match(@match_id)
  end
end
