[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/random-port)](http://www.rultor.com/p/yegor256/random-port)
[![We recommend RubyMine](http://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/random-port/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/random-port/actions/workflows/rake.yml)
[![Gem Version](https://badge.fury.io/rb/random-port.svg)](http://badge.fury.io/rb/random-port)
[![Maintainability](https://api.codeclimate.com/v1/badges/349b8c31884d3b34d926/maintainability)](https://codeclimate.com/github/yegor256/random-port/maintainability)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/random-port/master/frames)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/random-port/blob/master/LICENSE.txt)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/random-port.svg)](https://codecov.io/github/yegor256/random-port?branch=master)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/random-port)](https://hitsofcode.com/view/github/random-port/mailanes)

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

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
