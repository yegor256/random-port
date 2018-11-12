[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/random-port)](http://www.rultor.com/p/yegor256/random-port)
[![We recommend RubyMine](http://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/random-port.svg)](https://travis-ci.org/yegor256/random-port)
[![Gem Version](https://badge.fury.io/rb/random-port.svg)](http://badge.fury.io/rb/random-port)
[![Maintainability](https://api.codeclimate.com/v1/badges/349b8c31884d3b34d926/maintainability)](https://codeclimate.com/github/yegor256/random-port/maintainability)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/random-port/master/frames)

It's a simple Ruby gem to get a random TCP port.

First, install it:

```bash
$ gem install random-port
```

Then, use it like this, to reserve a random TCP port:

```ruby
require 'random-port'
port = RandomPort::Pool.new.acquire
```

The `Pool` guarantees that the port won't be used again. You can put
the port back to the pool after usage:

```ruby
RandomPort::Pool.new.acquire do |port|
  # Use the TCP port. It will be returned back
  # to the pool afterwards.
end
```

You can do it without the block:

```ruby
pool = RandomPort::Pool.new
port = pool.acquire
pool.release(port)
```

You can also use a pre-defined `Pool::SINGLETON` singleton:

```ruby
RandomPort::Pool::SINGLETON.acquire do |port|
  # Use it here...
end
```

The pool is thread-safe by default.
You can configure it to be
not-thread-safe, using optional `sync` argument of the constructor.

# How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ rake
```

If it's clean and you don't see any error messages, submit your pull request.

# License

(The MIT License)

Copyright (c) 2018 Yegor Bugayenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
