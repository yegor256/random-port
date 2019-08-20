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

require 'socket'
require 'monitor'

module RandomPort
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
  # not-thread-safe, using optional <tt>sync</tt> argument of the constructor.
  #
  # Author:: Yegor Bugayenko (yegor256@gmail.com)
  # Copyright:: Copyright (c) 2018 Yegor Bugayenko
  # License:: MIT
  class Pool
    # If can't acquire by time out.
    class Timeout < StandardError; end

    # Ctor.
    def initialize(sync: false, limit: 65_536)
      @ports = []
      @sync = sync
      @monitor = Monitor.new
      @limit = limit
    end

    # Application wide pool of ports
    SINGLETON = Pool.new

    # How many ports acquired now?
    def count
      @ports.count
    end

    # Is it empty?
    def empty?
      @ports.empty?
    end

    # Acquire a new random TCP port.
    #
    # You can specify the amount of seconds to wait until a new port
    # is available.
    def acquire(timeout: 4)
      start = Time.now
      loop do
        if Time.now > start + timeout
          raise Timeout, "Can't find a place in the pool of #{@limit} ports \
in #{format('%.02f', Time.now - start)}s"
        end
        next if @ports.count >= @limit
        server = TCPServer.new('127.0.0.1', 0)
        port = server.addr[1]
        server.close
        safe do
          next if @ports.include?(port)
          @ports << port
        end
        return port unless block_given?
        begin
          return yield port
        ensure
          safe { @ports.delete(port) }
        end
      end
    end

    # Return it back to the pool.
    def release(port)
      safe { @ports.delete(port) }
    end

    private

    def safe
      if @sync
        @monitor.synchronize { yield }
      else
        yield
      end
    end
  end
end
