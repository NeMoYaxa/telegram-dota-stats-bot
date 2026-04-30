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

  #    MY
  def test_fetch_hero_build_returns_best_items
    fake_json = {
      data: {
        constants: {
          hero: { "displayName" => "Pudge", "shortName" => "pudge" },
          items: [
            { "id" => 69, "displayName" => "Blink Dagger", "shortName" => "blink" },
            { "id" => 208, "displayName" => "Aghanim's Scepter", "shortName" => "aghs" }
          ]
        },
        heroStats: {
          itemFullPurchase: [
            { "itemId" => 69, "time" => 15, "winsAverage" => 0.55 },
            { "itemId" => 69, "time" => 20, "winsAverage" => 0.60 },
            { "itemId" => 208, "time" => 35, "winsAverage" => 0.70 }
          ]
        }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_hero_build(14)

    refute_nil res
    assert_equal "Pudge", res[:name]
    assert res[:best_items].is_a?(Array)
    assert res[:best_items].any? { |i| i[:item_name] == "Blink Dagger" }
  end



  def test_hero_build_returns_nil_when_no_hero
    fake_json = { data: { constants: { hero: nil }, heroStats: { itemFullPurchase: [] } } }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_hero_build(999)
    assert_nil res
  end



  def test_parse_best_items_by_time_removes_duplicates
    hero = @hero
    purchases = [
      { "itemId" => 1, "time" => 5, "winsAverage" => 0.70 },
      { "itemId" => 1, "time" => 15, "winsAverage" => 0.80 },
      { "itemId" => 2, "time" => 25, "winsAverage" => 0.65 },
      { "itemId" => 3, "time" => 35, "winsAverage" => 0.60 }
    ]
    items_map = {
      1 => { name: "Item 1", short_name: "item1" },
      2 => { name: "Item 2", short_name: "item2" },
      3 => { name: "Item 3", short_name: "item3" }
    }

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)

    item_ids = results.map { |r| r[:item_id] }
    assert_equal item_ids.uniq.size, item_ids.size
  end


  def test_parse_best_items_by_time_returns_six_intervals
    hero = @hero
    purchases = (1..20).map do |i|
      { "itemId" => i, "time" => rand(0..60), "winsAverage" => rand(0.4..0.8) }
    end
    items_map = {}

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)

    assert_equal 6, results.size
    assert_equal ["0-10", "11-20", "21-30", "31-40", "41-50", "51-60"],
                 results.map { |r| r[:interval] }
  end

  
  def test_parse_best_items_by_time_selects_best_winrate_per_interval
    hero = @hero
    purchases = [
      { "itemId" => 1, "time" => 5, "winsAverage" => 0.50 },
      { "itemId" => 2, "time" => 8, "winsAverage" => 0.80 },
      { "itemId" => 3, "time" => 15, "winsAverage" => 0.60 },
      { "itemId" => 4, "time" => 18, "winsAverage" => 0.75 }
    ]
    items_map = {
      1 => { name: "Item 1", short_name: "i1" },
      2 => { name: "Item 2", short_name: "i2" },
      3 => { name: "Item 3", short_name: "i3" },
      4 => { name: "Item 4", short_name: "i4" }
    }

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)

    assert_equal 2, results[0][:item_id]
    assert_equal 4, results[1][:item_id]
  end
end