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
            { heroId: 1, winCount: 1500, matchCount: 2500 }, 
            { heroId: 2, winCount: 2000, matchCount: 3000 }  
          ] 
        },
        constants: { 
          heroes: [
            { id: 1, displayName: "Anti-Mage" },
            { id: 2, displayName: "Axe" }
          ] 
        }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_recommended(1)
    
    assert_equal "Axe", res.first[:name]
    assert_equal 66.67, res.first[:win_rate]
    assert res.size <= 3
  end

  def test_parse_hero_details_format
    fake_json = {
      data: {
        constants: { 
          hero: { displayName: "Pudge", shortName: "pudge" }
        },
        heroStats: { 
          stats: [{ winCount: 5000, matchCount: 10000 }] 
        }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_hero_details(14)
    
    assert_equal "Pudge", res[:name]
    assert_includes res[:image_url], "pudge"
    assert_equal "7.41b", res[:patch]
    assert_equal "💠 Divine / Immortal", res[:rank_text]
  end

  def test_recommended_filters_low_match_count
    fake_json = {
      data: {
        heroStats: { 
          stats: [{ heroId: 1, winCount: 50, matchCount: 100 }] 
        },
        constants: { heroes: [{ id: 1, displayName: "Anti-Mage" }] }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_recommended(1)
    assert_empty res
  end
end