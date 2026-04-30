# frozen_string_literal: true

require_relative "test_helper"

class TestHero < Minitest::Test
  def setup
    ENV["STRATZ_TOKEN"] = "fake_token"
    @hero = TelegramDotaStatsBot::Hero.new
    @url = TelegramDotaStatsBot::Client::STRATZ_GRAPHQL
  end

  #  ТЕСТЫ ДЛЯ fetch_recommended

  def test_parse_recommended_returns_sorted_heroes
    fake_json = {
      data: {
        heroStats: {
          stats: [
            { "heroId" => 1, "winCount" => 2500, "matchCount" => 5000 },
            { "heroId" => 2, "winCount" => 4000, "matchCount" => 5000 }
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

    refute_empty res
    assert_equal "Axe", res.first[:name]
    assert_equal 80.0, res.first[:win_rate]
    assert res.size <= 3
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
    assert_empty res
  end

  #  ТЕСТЫ ДЛЯ fetch_hero_details

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
    assert_equal 50.0, res[:win_rate]
    assert_equal 10000, res[:match_count]
  end

  def test_hero_details_returns_nil_when_no_data
    fake_json = { data: { constants: { hero: nil }, heroStats: { stats: [] } } }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_hero_details(999)
    assert_nil res
  end

  #  ТЕСТЫ ДЛЯ fetch_all_heroes
  def test_fetch_all_heroes_returns_sorted_list
    fake_json = {
      data: {
        constants: {
          heroes: [
            { "id" => 14, "displayName" => "Pudge", "shortName" => "pudge" },
            { "id" => 1, "displayName" => "Anti-Mage", "shortName" => "antimage" },
            { "id" => 2, "displayName" => "Axe", "shortName" => "axe" }
          ]
        }
      }
    }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_all_heroes

    assert_equal 3, res.size
    assert_equal "Anti-Mage", res.first[:name]
    assert_equal "Axe", res[1][:name]
    assert_equal "Pudge", res.last[:name]
  end

  def test_fetch_all_heroes_returns_empty_when_no_data
    fake_json = { data: { constants: { heroes: nil } } }.to_json

    stub_request(:post, @url).to_return(status: 200, body: fake_json)

    res = @hero.fetch_all_heroes
    assert_empty res
  end

  #  ТЕСТЫ ДЛЯ fetch_hero_build

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
      { "itemId" => 2, "time" => 15, "winsAverage" => 0.80 },
      { "itemId" => 3, "time" => 25, "winsAverage" => 0.65 },
      { "itemId" => 4, "time" => 35, "winsAverage" => 0.60 },
      { "itemId" => 5, "time" => 45, "winsAverage" => 0.75 },
      { "itemId" => 6, "time" => 55, "winsAverage" => 0.55 }
    ]
    items_map = {}
    (1..6).each { |id| items_map[id] = { name: "Item #{id}", short_name: "item#{id}" } }

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)


    item_ids = results.map { |r| r[:item_id] }
    assert_equal 6, item_ids.uniq.size, "Должно быть 6 уникальных предметов"
    assert_equal 6, results.size, "Должно быть 6 интервалов"
  end

  def test_parse_best_items_by_time_returns_correct_amount_of_intervals
    hero = @hero

    purchases = [
      { "itemId" => 1, "time" => 5, "winsAverage" => 0.70 },
      { "itemId" => 2, "time" => 15, "winsAverage" => 0.80 },
      { "itemId" => 3, "time" => 25, "winsAverage" => 0.65 },
      { "itemId" => 4, "time" => 35, "winsAverage" => 0.60 },
      { "itemId" => 5, "time" => 45, "winsAverage" => 0.75 },
      { "itemId" => 6, "time" => 55, "winsAverage" => 0.55 }
    ]
    items_map = {}

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)

    assert_equal 6, results.size, "Если есть покупки во всех интервалах - должно быть 6"
    assert_equal ["0-10", "11-20", "21-30", "31-40", "41-50", "51-60"],
                 results.map { |r| r[:interval] }
  end

  def test_parse_best_items_by_time_handles_missing_intervals
    hero = @hero

    purchases = [
      { "itemId" => 1, "time" => 5, "winsAverage" => 0.70 },
      { "itemId" => 2, "time" => 55, "winsAverage" => 0.80 }
    ]
    items_map = {
      1 => { name: "Item 1", short_name: "i1" },
      2 => { name: "Item 2", short_name: "i2" }
    }

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)


    assert_equal 2, results.size, "Должны быть только интервалы с покупками"
    assert_equal ["0-10", "51-60"], results.map { |r| r[:interval] }
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

    assert_equal 2, results[0][:item_id], "В интервале 0-10 должен быть itemId 2"
    assert_equal 4, results[1][:item_id], "В интервале 11-20 должен быть itemId 4"
  end

  def test_parse_best_items_by_time_skips_empty_intervals
    hero = @hero

    purchases = [
      { "itemId" => 1, "time" => 5, "winsAverage" => 0.70 },
      { "itemId" => 2, "time" => 45, "winsAverage" => 0.80 },
      { "itemId" => 3, "time" => 55, "winsAverage" => 0.60 }
    ]
    items_map = {}

    results = hero.send(:parse_best_items_by_time_from_purchases, purchases, items_map)


    refute_includes results.map { |r| r[:interval] }, "21-30"
    refute_includes results.map { |r| r[:interval] }, "31-40"
  end

  #  ТЕСТЫ ДЛЯ calculate_win_r

  def test_calculate_win_rate_returns_correct_percentage
    assert_equal 50.0, @hero.calculate_win_rate(100, 50)
    assert_equal 75.0, @hero.calculate_win_rate(100, 75)
    assert_equal 0.0, @hero.calculate_win_rate(100, 0)
    assert_equal 100.0, @hero.calculate_win_rate(100, 100)
  end

  def test_calculate_win_rate_handles_zero_matches
    assert_equal 0.0, @hero.calculate_win_rate(0, 0)
    assert_equal 0.0, @hero.calculate_win_rate(0, 10)
  end



  def test_handles_api_error_gracefully
    stub_request(:post, @url).to_return(status: 500, body: "Internal Server Error")

    res = @hero.fetch_recommended(1)
    assert_empty res

    res2 = @hero.fetch_hero_details(14)
    assert_nil res2

    res3 = @hero.fetch_all_heroes
    assert_empty res3
  end

  def test_handles_timeout_gracefully
    stub_request(:post, @url).to_timeout

    res = @hero.fetch_recommended(1)
    assert_empty res
  end
end