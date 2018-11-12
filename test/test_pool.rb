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
require_relative '../lib/random-port/pool'

# Pool test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
module RandomPort
  class TestAmount < Minitest::Test
    def test_acquires_and_releases
      pool = Pool.new
      port = pool.acquire
      assert(!port.nil?)
      assert(port.positive?)
      pool.release(port)
    end

    def test_acquires_and_releases_in_block
      Pool.new.acquire do |port|
        assert(!port.nil?)
        assert(port.positive?)
      end
    end

    def test_acquires_and_releases_from_singleton
      Pool::SINGLETON.acquire do |port|
        assert(!port.nil?)
        assert(port.positive?)
      end
    end

    def test_acquires_unique_numbers
      total = 25
      numbers = (0..total - 1).map { Pool::SINGLETON.acquire }
      assert_equal(total, numbers.uniq.count)
    end
  end
end
