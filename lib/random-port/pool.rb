# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'monitor'
require 'socket'
require 'tago'
require_relative 'module'

# Pool of TCP ports.
#
# Use it like this:
#
#  RandomPort::Pool.new.acquire do |port|
#    # Use the TCP port. It will be returned back
#    # to the pool afterwards.
#  end
#
# You can specify the maximum number of ports to acquire using +limit+.
# If more acquisition requests arrive, an exception will be raised.
#
# The class is thread-safe by default. You can configure it to be
# non-thread-safe using the optional +sync+ argument of the constructor,
# passing <tt>FALSE</tt>.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2026 Yegor Bugayenko
# License:: MIT
class RandomPort::Pool
  # Raised when a port cannot be acquired within the timeout period.
  class Timeout < StandardError; end

  # @return [Integer] The maximum number of ports that can be acquired from this pool
  attr_reader :limit

  # Constructor.
  # @param [Boolean] sync Set to FALSE if you want this pool to be non-thread-safe
  # @param [Integer] limit The maximum number of ports that can be acquired from the pool
  # @param [Integer] start The first port number to try when acquiring
  def initialize(sync: true, limit: 65_536, start: 1025)
    @ports = []
    @sync = sync
    @monitor = Monitor.new
    @limit = limit
    @next = start
  end

  # Application-wide singleton pool of ports.
  SINGLETON = RandomPort::Pool.new

  # Returns the number of ports currently acquired from the pool.
  # @return [Integer] The count of acquired ports
  def count
    @ports.count
  end
  alias size count

  # Checks if the pool is empty (no ports are currently acquired).
  # @return [Boolean] TRUE if no ports are acquired, FALSE otherwise
  def empty?
    @ports.empty?
  end

  # Acquires one or more available TCP ports from the pool.
  #
  # You can specify the number of ports to acquire. If it's more than one,
  # an array will be returned. If a block is given, the port(s) will be
  # automatically released after the block execution.
  #
  # @param [Integer] total The number of ports to acquire (default: 1)
  # @param [Integer] timeout The maximum seconds to wait for port availability
  # @yield [Integer|Array<Integer>] The acquired port(s)
  # @return [Integer|Array<Integer>] The acquired port(s) if no block given
  # @raise [Timeout] If ports cannot be acquired within the timeout period
  def acquire(total = 1, timeout: 4)
    start = Time.now
    attempt = 0
    loop do
      if Time.now > start + timeout
        raise \
          Timeout,
          "Can't find a place in the pool of #{@limit} ports " \
          "(#{@ports.size} already occupied) " \
          "for #{total} port(s), after #{attempt} attempts in #{start.ago}"
      end
      attempt += 1
      opts = safe { group(total) }
      if opts.nil?
        @next += 1
      else
        @next = opts.max + 1
      end
      @next = 0 if @next > 65_535
      next if opts.nil?
      opts = opts[0] if total == 1
      return opts unless block_given?
      begin
        return yield opts
      ensure
        release(opts)
      end
    end
  end

  # Releases one or more ports back to the pool.
  # @param [Integer|Array<Integer>] port The TCP port number(s) to release
  # @return [nil]
  def release(port)
    safe do
      if port.is_a?(Array)
        port.each { |p| @ports.delete(p) }
      else
        @ports.delete(port)
      end
    end
  end

  private

  # Attempts to acquire a contiguous group of ports.
  # @param [Integer] total The number of ports to acquire
  # @return [Array<Integer>|nil] An array of port numbers if successful, nil otherwise
  def group(total)
    return nil if @ports.count + total > @limit
    opts = Array.new(total, 0)
    begin
      (0..(total - 1)).each do |i|
        port = i.zero? ? @next : opts[i - 1] + 1
        opts[i] = take(port)
      end
    rescue Errno::EADDRINUSE, SocketError
      return nil
    end
    return nil if opts.any? { |p| @ports.include?(p) }
    d = total * (total - 1) / 2
    return nil unless opts.inject(&:+) - (total * opts.min) == d
    @ports += opts
    opts
  end

  # Verifies that a specific TCP port is available for use.
  #
  # Attempts to bind to the port on various interfaces to ensure availability.
  # If the port is occupied, this method raises an error (+Errno::EADDRINUSE+).
  #
  # @param [Integer] port The port number to verify
  # @return [Integer] The same port number if available
  # @raise [Errno::EADDRINUSE] If the port is already in use
  # @raise [SocketError] If there's a socket-related error
  def take(port)
    ['127.0.0.1', '::1', '0.0.0.0', 'localhost'].each do |host|
      begin
        TCPServer.new(host, port).close
      rescue Errno::EADDRNOTAVAIL
        next
      end
    end
    port
  end

  # Executes a block of code with or without thread synchronization.
  # @param block The block of code to execute
  # @return The result of the block execution
  def safe(&block)
    if @sync
      @monitor.synchronize(&block)
    else
      yield
    end
  end
end
