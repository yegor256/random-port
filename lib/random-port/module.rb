# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Main module that contains all RandomPort classes and utilities.
#
# This module provides a simple way to acquire random TCP ports
# that are guaranteed to be available for use. It includes a Pool
# class that manages port allocation and ensures thread safety.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2026 Yegor Bugayenko
# License:: MIT
module RandomPort
  extend Forwardable

  def_delegators :'RandomPort::Pool::SINGLETON', :acquire, :release, :count, :size, :empty?
  module_function :acquire, :release, :count, :size, :empty?
end
