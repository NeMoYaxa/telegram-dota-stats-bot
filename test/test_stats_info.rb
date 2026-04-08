# frozen_string_literal: true

require "test_helper"

class TestStatsInfo < Minitest::Test
  include TelegramDotaStatsBot::StatsInfo

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
    medal_ancient =rank_to_medal(55)

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
end
