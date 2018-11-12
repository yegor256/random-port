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
  # The class is thread-safe, by default. You can configure it to be
  # not-thread-safe, using optional <tt>sync</tt> argument of the constructor.
  #
  # Author:: Yegor Bugayenko (yegor256@gmail.com)
  # Copyright:: Copyright (c) 2018 Yegor Bugayenko
  # License:: MIT
  class Pool
    def initialize(sync: false)
      @ports = []
      @sync = sync
      @monitor = Monitor.new
    end

    # Application wide pool of ports
    SINGLETON = Pool.new

    # Acquire a new random TCP port.
    def acquire
      loop do
        server = TCPServer.new('127.0.0.1', 0)
        port = server.addr[1]
        server.close
        next if @ports.include?(port)
        safe { @ports << port }
        return port unless block_given?
        yield port
        safe { @ports.delete(port) }
        break
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
