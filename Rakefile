# frozen_string_literal: true

require 'rake/testtask'
require 'minitest/autorun'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/weenat/*_test.rb'
  t.warning = false
end
task default: :test
