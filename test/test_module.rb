# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/random-port'

# Test suite for RandomPort module.
class TestRandomPort < Minitest::Test
  def test_delegate_acquire_method_without_parameters_with_block_to_pool_singleton
    RandomPort.acquire do |port|
      assert_instance_of(Integer, port)
    end
  end

  def test_delegate_acquire_method_with_parameters_and_block_to_pool_singleton
    RandomPort.acquire(2, timeout: 3) do |ports|
      assert_pattern { ports => [Integer, Integer] }
    end
  end

  def test_delegate_acquire_method_without_parameters_and_block_to_pool_singleton
    port = RandomPort.acquire
    assert_instance_of(Integer, port)
    assert_predicate(RandomPort.size, :positive?)
    assert_predicate(RandomPort.count, :positive?)
    refute_predicate(RandomPort, :empty?)
    RandomPort.release(port)
  end

  def test_delegate_acquire_method_with_parameters_and_without_block_to_pool_singleton
    ports = RandomPort.acquire(3, timeout: 1)
    assert_pattern { ports => [Integer, Integer, Integer] }
    assert_predicate(RandomPort.size, :positive?)
    assert_predicate(RandomPort.count, :positive?)
    refute_predicate(RandomPort, :empty?)
    RandomPort.release(ports)
  end
end
