# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/random-port'
require_relative 'test__helper'

# Test suite for RandomPort module.
class TestRandomPort < Minitest::Test
  def test_acquire_no_args_with_block
    RandomPort.acquire do |port|
      assert_instance_of(Integer, port)
    end
  end

  def test_acquire_with_args_and_block
    RandomPort.acquire(2, timeout: 3) do |ports|
      assert_pattern { ports => [Integer, Integer] }
    end
  end

  def test_acquire_no_args_no_block
    port = RandomPort.acquire
    assert_instance_of(Integer, port)
    assert_predicate(RandomPort.size, :positive?)
    assert_predicate(RandomPort.count, :positive?)
    refute_predicate(RandomPort, :empty?)
    RandomPort.release(port)
  end

  def test_acquire_with_args_no_block
    ports = RandomPort.acquire(3, timeout: 1)
    assert_pattern { ports => [Integer, Integer, Integer] }
    assert_predicate(RandomPort.size, :positive?)
    assert_predicate(RandomPort.count, :positive?)
    refute_predicate(RandomPort, :empty?)
    RandomPort.release(ports)
  end
end
