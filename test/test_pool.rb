# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'threads'
require_relative '../lib/random-port/pool'

# Pool test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
class RandomPort::TestPool < Minitest::Test
  def test_acquires_and_releases
    pool = RandomPort::Pool.new
    port = pool.acquire
    server = TCPServer.new(port)
    server.close
    assert(!port.nil?)
    assert(port.positive?)
    pool.release(port)
  end

  def test_acquires_and_releases_three_ports
    pool = RandomPort::Pool.new(limit: 3)
    assert_equal(0, pool.size)
    ports = pool.acquire(3, timeout: 16)
    ports.each do |p|
      server = TCPServer.new(p)
      server.close
    end
    assert_equal(3, pool.size)
    assert_equal(3, ports.count)
    pool.release(ports)
    assert_equal(0, pool.size)
  end

  def test_acquires_and_releases_three_ports_in_block
    pool = RandomPort::Pool.new(limit: 3)
    assert_equal(0, pool.size)
    pool.acquire(3, timeout: 16) do |ports|
      assert(ports.is_a?(Array))
      assert_equal(3, ports.count)
      assert_equal(3, pool.size)
      ports.each do |p|
        server = TCPServer.new(p)
        server.close
      end
    end
    assert_equal(0, pool.size)
  end

  def test_acquires_and_releases_in_block
    result = RandomPort::Pool.new.acquire do |port|
      assert(!port.nil?)
      assert(port.positive?)
      123
    end
    assert_equal(123, result)
  end

  def test_acquires_and_releases_in_threads
    pool = RandomPort::Pool.new
    Threads.new(10).assert do
      pool.acquire(5) do |ports|
        ports.each do |p|
          server = TCPServer.new(p)
          server.close
        end
      end
    end
  end

  def test_acquires_and_releases_safely
    pool = RandomPort::Pool.new
    assert_raises do
      pool.acquire do
        raise 'Itended'
      end
    end
    assert(pool.count.zero?)
  end

  def test_acquires_and_releases_from_singleton
    RandomPort::Pool::SINGLETON.acquire do |port|
      assert(!port.nil?)
      assert(port.positive?)
    end
  end

  def test_acquires_unique_numbers
    total = 25
    numbers = (0..total - 1).map { RandomPort::Pool::SINGLETON.acquire }
    assert_equal(total, numbers.uniq.count)
  end

  def test_raises_when_too_many
    pool = RandomPort::Pool.new(limit: 1)
    pool.acquire
    assert_raises RandomPort::Pool::Timeout do
      pool.acquire(timeout: 0.1)
    end
  end

  def test_acquires_unique_numbers_in_no_sync_mode
    total = 25
    pool = RandomPort::Pool.new(sync: false)
    numbers = (0..total - 1).map { pool.acquire }
    assert_equal(total, numbers.uniq.count)
  end
end
