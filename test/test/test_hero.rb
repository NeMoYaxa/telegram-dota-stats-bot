# frozen_string_literal: true

require "test_helper"

class TestHero < Minitest::Test
  def setup
    @hero = TelegramDotaStatsBot::Hero.new
    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
  end

  def test_parse_recommended_returns_sorted_heroes
    fake_json = {
      data: {
        heroStats: { stats: [{ heroId: 1, winGameCount: 60, matchCount: 100 }] },
        constants: { heroes: [{ id: 1, displayName: "Anti-Mage" }] }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_recommended(1)
    assert_equal "Anti-Mage", res.first[:name]
    assert_equal 60.0, res.first[:win_rate]
  end

  def test_parse_hero_details_format
    fake_json = {
      data: {
        constants: { hero: { displayName: "Pudge", shortName: "pudge" } },
        heroStats: { hero: { winGameCount: 50, matchCount: 100, itemBootPurchase: [{ itemId: 29 }] } }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_hero_details(14)
    assert_equal "Pudge", res[:name]
    assert_includes res[:icon_url], "pudge"
  end
end