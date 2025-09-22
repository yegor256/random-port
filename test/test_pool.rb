# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'qbash'
require 'shellwords'
require 'socket'
require 'threads'
require_relative '../lib/random-port/pool'

# Test suite for RandomPort::Pool.
#
# These tests verify that the pool correctly acquires and releases TCP ports,
# handles thread safety, manages port limits, and properly detects busy ports.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2025 Yegor Bugayenko
# License:: MIT
class RandomPort::TestPool < Minitest::Test
  def test_acquires_and_releases
    pool = RandomPort::Pool.new
    port = pool.acquire
    server = TCPServer.new('localhost', port)
    server.close
    refute_nil(port)
    assert_predicate(port, :positive?)
    pool.release(port)
  end

  def test_acquires_and_releases_three_ports
    pool = RandomPort::Pool.new(limit: 3)
    assert_equal(0, pool.size)
    ports = pool.acquire(3, timeout: 16)
    ports.each do |p|
      server = TCPServer.new('localhost', p)
      server.close
    end
    assert_equal(3, pool.size)
    assert_equal(3, ports.count)
    pool.release(ports)
    assert_equal(0, pool.size)
  end

  def test_skips_truly_busy_port
    port = RandomPort::Pool.new.acquire
    server = TCPServer.new('127.0.0.1', port)
    other = RandomPort::Pool.new(start: port).acquire
    refute_equal(other, port)
    server.close
  end

  def test_skips_externally_busy_port
    skip 'Not supported on Windows' if Gem.win_platform?
    ['127.0.0.1', 'localhost', '::1', '0.0.0.0'].each do |host|
      Dir.mktmpdir do |home|
        port = RandomPort::Pool.new.acquire
        started = File.join(home, 'started.txt')
        enough = File.join(home, 'enough.txt')
        t =
          Thread.new do
            qbash(
              [
                'ruby', '-e',
                Shellwords.escape(
                  "
                  require 'socket'
                  require 'fileutils'
                  TCPServer.new('#{host}', #{port})
                  FileUtils.touch('#{started}')
                  loop do
                    break if File.exist?('#{enough}')
                  end
                  "
                )
              ]
            )
          end
        loop do
          break if File.exist?(started)
        end
        other = RandomPort::Pool.new(start: port).acquire
        FileUtils.touch(enough)
        t.join
        refute_equal(other, port)
      end
    end
  end

  def test_acquires_and_releases_three_ports_in_block
    pool = RandomPort::Pool.new(limit: 3)
    assert_equal(0, pool.size)
    pool.acquire(3, timeout: 16) do |ports|
      assert_kind_of(Array, ports)
      assert_equal(3, ports.count)
      assert_equal(3, pool.size)
      ports.each do |p|
        server = TCPServer.new('localhost', p)
        server.close
      end
    end
    assert_equal(0, pool.size)
  end

  def test_acquires_and_releases_in_block
    result = RandomPort::Pool.new.acquire do |port|
      refute_nil(port)
      assert_predicate(port, :positive?)
      123
    end
    assert_equal(123, result)
  end

  def test_acquires_and_releases_in_threads
    pool = RandomPort::Pool.new
    Threads.new(100).assert do
      pool.acquire(5) do |ports|
        ports.each do |p|
          server = TCPServer.new('localhost', p)
          server.close
        end
      end
    end
  end

  def test_acquires_and_releases_safely
    pool = RandomPort::Pool.new
    assert_raises(StandardError) do
      pool.acquire do
        raise 'Intended'
      end
    end
    assert_predicate(pool.count, :zero?)
  end

  def test_acquires_and_releases_from_singleton
    RandomPort::Pool::SINGLETON.acquire do |port|
      refute_nil(port)
      assert_predicate(port, :positive?)
    end
  end

  def test_acquires_unique_numbers
    total = 25
    numbers = (0..(total - 1)).map { RandomPort::Pool::SINGLETON.acquire }
    assert_equal(total, numbers.uniq.count)
  end

  def test_acquires_unique_numbers_in_block
    total = 25
    numbers = (0..(total - 1)).map do
      RandomPort::Pool::SINGLETON.acquire do |port|
        port
      end
    end
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
    numbers = (0..(total - 1)).map { pool.acquire }
    assert_equal(total, numbers.uniq.count)
  end

  def test_taking_port_raises_address_not_available_error
    original_impl = TCPServer.method(:new)

    raise_error_stub = lambda do |host, port|
      raise Errno::EADDRNOTAVAIL if %w[127.0.0.1 ::1].include? host
      original_impl.call(host, port)
    end

    TCPServer.stub(:new, raise_error_stub) do
      pool = RandomPort::Pool.new
      port = pool.acquire
      refute_nil(port)
      assert_predicate(port, :positive?)
      pool.release(port)
    end
  end
end
