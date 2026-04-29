# frozen_string_literal: true

require_relative "test_helper"

class TestHero < Minitest::Test
  def setup
    ENV["STRATZ_TOKEN"] = "fake_token"
    @hero = TelegramDotaStatsBot::Hero.new
    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
  end

  def test_parse_recommended_returns_sorted_heroes
    fake_json = {
      data: {
        heroStats: { 
          stats: [
            { "heroId" => 1, "winCount" => 2500, "matchCount" => 5000 }, # WR 50%
            { "heroId" => 2, "winCount" => 4000, "matchCount" => 5000 }  # WR 80%
          ] 
        },
        constants: { 
          heroes: [
            { "id" => 1, "displayName" => "Anti-Mage" },
            { "id" => 2, "displayName" => "Axe" }
          ] 
        }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_recommended(1)
    
    refute_empty res, "Массив героев не должен быть пустым (проверь фильтр matchCount в hero.rb)"
    assert_equal "Axe", res.first[:name], "Первым должен быть герой с самым высоким винрейтом"
    assert_equal 80.0, res.first[:win_rate]
    assert res.size <= 3
  end

  def test_parse_hero_details_format
    fake_json = {
      data: {
        constants: { 
          hero: { "displayName" => "Pudge", "shortName" => "pudge" }
        },
        heroStats: { 
          stats: [{ "winCount" => 5000, "matchCount" => 10000 }] 
        }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_hero_details(14)
    
    assert_equal "Pudge", res[:name]
    assert_includes res[:image_url], "pudge"
    assert_equal "7.41b", res[:patch]
  end

  def test_recommended_filters_low_match_count
    fake_json = {
      data: {
        heroStats: { 
          stats: [{ "heroId" => 1, "winCount" => 50, "matchCount" => 100 }] 
        },
        constants: { heroes: [{ "id" => 1, "displayName" => "Anti-Mage" }] }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_recommended(1)
    assert_empty res, "Герои с matchCount < 4000 не должны попадать в выборку"
  end
end