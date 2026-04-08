# frozen_string_literal: true

require "test_helper"

class TestStatsInfo < Minitest::Test
  include TelegramDotaStatsBot::StatsInfo

  def setup
    @fake_json = <<~JSON
      {
        "data": {
          "constants": {
            "regions": [
              { "id": 0,  "name": "unspecified",                  "clientName": null },
              { "id": 1,  "name": "USWest",                       "clientName": "US West" },
              { "id": 2,  "name": "USEast",                       "clientName": "US East" },
              { "id": 3,  "name": "Europe",                       "clientName": "Europe West" },
              { "id": 5,  "name": "Singapore",                    "clientName": "SE Asia" },
              { "id": 6,  "name": "Dubai",                        "clientName": "Dubai" },
              { "id": 7,  "name": "Australia",                    "clientName": "Australia" },
              { "id": 8,  "name": "Stockholm",                    "clientName": "Russia" },
              { "id": 9,  "name": "Austria",                      "clientName": "EU East" },
              { "id": 10, "name": "Brazil",                       "clientName": "South America" },
              { "id": 11, "name": "SouthAfrica",                  "clientName": "South Africa" },
              { "id": 12, "name": "PerfectWorldTelecom",          "clientName": "China" },
              { "id": 13, "name": "PerfectWorldUnicom",           "clientName": "China" },
              { "id": 14, "name": "Chile",                        "clientName": "Chile" },
              { "id": 15, "name": "Peru",                         "clientName": "Peru" },
              { "id": 16, "name": "India",                        "clientName": "India" },
              { "id": 17, "name": "PerfectWorldTelecomGuangdong", "clientName": "China" },
              { "id": 18, "name": "PerfectWorldTelecomZhejiang",  "clientName": "China" },
              { "id": 19, "name": "Japan",                        "clientName": "Japan" },
              { "id": 20, "name": "PerfectWorldTelecomWuhan",     "clientName": "China" },
              { "id": 25, "name": "PerfectWorldUnicomTianjin",    "clientName": "China" },
              { "id": 37, "name": "Taiwan",                       "clientName": null },
              { "id": 38, "name": "Argentina",                    "clientName": null }
            ]
          }
        }
      }
    JSON

    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
  end

  def test_match_duration_to_string_time_returns_nil
    assert_nil match_duration_to_string_time(nil)
  end

  def test_match_duration_to_string_time_returns_correct_data1
    assert_equal "20мин. 34сек.", match_duration_to_string_time(1234)
  end

  def test_match_duration_to_string_time_returns_correct_data2
    assert_equal "10мин. 0сек.", match_duration_to_string_time(600)
  end

  def test_rank_to_medal_nil
    medal_nil = rank_to_medal(nil)

    assert_equal "Калибровка", medal_nil
  end

  def test_rank_to_medal_negative
    medal_nil = rank_to_medal(-1)

    assert_equal "Калибровка", medal_nil
  end

  def test_rank_to_medal_herald
    medal_herald = rank_to_medal(1)

    assert_equal "Рекрут", medal_herald
  end

  def test_rank_to_medal_guardian
    medal_guardian = rank_to_medal(11)

    assert_equal "Страж", medal_guardian
  end

  def test_rank_to_medal_crusader
    medal_crusader = rank_to_medal(22)

    assert_equal "Рыцарь", medal_crusader
  end

  def test_rank_to_medal_archon
    medal_archon = rank_to_medal(33)

    assert_equal "Герой", medal_archon
  end

  def test_rank_to_medal_legend
    medal_legend = rank_to_medal(44)

    assert_equal "Легенда", medal_legend
  end

  def test_rank_to_medal_ancient
    medal_ancient = rank_to_medal(55)

    assert_equal "Властелин", medal_ancient
  end

  def test_rank_to_medal_divine
    medal_divine = rank_to_medal(76)

    assert_equal "Божество", medal_divine
  end

  def test_rank_to_medal_immortal
    medal_immortal = rank_to_medal(80)

    assert_equal "Титан", medal_immortal
  end

  def test_fetch_regions_returns_json_200
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal @fake_json, fetch_regions
  end

  def test_parse_regions_returns_correct_hash
    fake_json = <<~JSON
      {
        "data": {
          "constants": {
            "regions": [
              { "id": 6,  "name": "Dubai", "clientName": "Dubai" }
            ]
          }
        }
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    regions_data = parse_regions

    expected_data = {
      6 => "Dubai"
    }

    assert_equal expected_data, regions_data
  end

  def test_parse_match_nil_hash_returns_nil
    fake_json = nil

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil parse_regions
  end

  def test_parse_match_empty_hash_returns_nil
    fake_json = ""

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil parse_regions
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

    assert_nil parse_regions
  end

  def test_parse_match_graphql_no_match_returns_nil
    fake_json = <<~JSON
      {
         "message": "Some GraphQL error"
      }
    JSON

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil parse_regions
  end

  def test_parse_match_error_json_returns_nil
    fake_json = "abba"

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    assert_nil parse_regions
  end

  def test_region_id_to_client_name_nil_returns_unspecified
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Unspecified", region_id_to_client_name(nil)
  end

  def test_region_id_to_client_name_0_returns_unspecified
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Unspecified", region_id_to_client_name(0)
  end

  def test_region_id_to_client_name_1_returns_us_west
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "US West", region_id_to_client_name(1)
  end

  def test_region_id_to_client_name_2_returns_us_east
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "US East", region_id_to_client_name(2)
  end

  def test_region_id_to_client_name_3_returns_europe_west
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Europe West", region_id_to_client_name(3)
  end

  def test_region_id_to_client_name_5_returns_se_asia
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "SE Asia", region_id_to_client_name(5)
  end

  def test_region_id_to_client_name_6_returns_dubai
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Dubai", region_id_to_client_name(6)
  end

  def test_region_id_to_client_name_7_returns_australia
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Australia", region_id_to_client_name(7)
  end

  def test_region_id_to_client_name_8_returns_russia
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Russia", region_id_to_client_name(8)
  end

  def test_region_id_to_client_name_9_returns_eu_east
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "EU East", region_id_to_client_name(9)
  end

  def test_region_id_to_client_name_10_returns_south_america
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "South America", region_id_to_client_name(10)
  end

  def test_region_id_to_client_name_11_returns_south_africa
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "South Africa", region_id_to_client_name(11)
  end

  def test_region_id_to_client_name_12_returns_china
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "China", region_id_to_client_name(12)
  end

  def test_region_id_to_client_name_13_returns_china
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "China", region_id_to_client_name(13)
  end

  def test_region_id_to_client_name_14_returns_chile
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Chile", region_id_to_client_name(14)
  end

  def test_region_id_to_client_name_15_returns_peru
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Peru", region_id_to_client_name(15)
  end

  def test_region_id_to_client_name_16_returns_india
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "India", region_id_to_client_name(16)
  end

  def test_region_id_to_client_name_17_returns_china
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "China", region_id_to_client_name(17)
  end

  def test_region_id_to_client_name_18_returns_china
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "China", region_id_to_client_name(18)
  end

  def test_region_id_to_client_name_19_returns_japan
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Japan", region_id_to_client_name(19)
  end

  def test_region_id_to_client_name_20_returns_china
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "China", region_id_to_client_name(20)
  end

  def test_region_id_to_client_name_25_returns_china
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "China", region_id_to_client_name(25)
  end

  def test_region_id_to_client_name_37_returns_taiwan
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Taiwan", region_id_to_client_name(37)
  end

  def test_region_id_to_client_name_38_returns_argentina
    stub_request(:post, @url).to_return(status: 200, body: @fake_json)

    assert_equal "Argentina", region_id_to_client_name(38)
  end
end
