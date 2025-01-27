# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018-2025 Yegor Bugayenko
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

require 'monitor'
require 'socket'
require 'tago'
require_relative 'module'

# Pool of TPC ports.
#
# Use it like this:
#
#  RandomPort::Pool.new.acquire do |port|
#    # Use the TCP port. It will be returned back
#    # to the pool afterwards.
#  end
#
# You can specify the maximum amount of ports to acquire, using +limit+.
# If more acquiring requests will arrive, an exception will be raised.
#
# The class is thread-safe, by default. You can configure it to be
# not-thread-safe, using optional +sync+ argument of the constructor,
# passing <tt>FALSE</tt>.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2025 Yegor Bugayenko
# License:: MIT
class RandomPort::Pool
  # If can't acquire by time out.
  class Timeout < StandardError; end

  attr_reader :limit

  # Ctor.
  # @param [Boolean] sync Set it to FALSE if you want this pool to be NOT thread-safe
  # @param [Integer] limit Set the maximum number of ports in the pool
  # @param [Integer] start The next port to try
  def initialize(sync: true, limit: 65_536, start: 1025)
    @ports = []
    @sync = sync
    @monitor = Monitor.new
    @limit = limit
    @next = start
  end

  # Application wide pool of ports
  SINGLETON = RandomPort::Pool.new

  # How many ports acquired now?
  def count
    @ports.count
  end
  alias size count

  # Is it empty?
  def empty?
    @ports.empty?
  end

  # Acquire a new random TCP port.
  #
  # You can specify the number of ports to acquire. If it's more than one,
  # an array will be returned.
  #
  # You can specify the amount of seconds to wait until a new port
  # is available.
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
      attempt +=  1
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

  # Return it/them back to the pool.
  # @param [Integer] port TCP port number to release
  # @return nil
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

  # Take a group of ports, if possible.
  # @param [Integer] total How many ports to take
  # @return [Array<Integer>|nil] Ports found or NIL if impossible now
  def group(total)
    return nil if @ports.count + total > @limit
    opts = Array.new(0, total)
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

  # Find one possible TCP port or raise exception if this port can't be used.
  #
  # If port is occupied, this method raises an error (+Errno::EADDRINUSE+).
  #
  # @param [Integer] port Suggested port number
  # @return [Integer] The same port number
  def take(port)
    ['127.0.0.1', '::1'].each do |host|
      TCPServer.new(host, port).close
    end
    port
  end

  def safe(&block)
    if @sync
      @monitor.synchronize(&block)
    else
      yield
    end
  end
end
