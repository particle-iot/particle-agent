#!/usr/bin/env rake

require 'bundler'
Bundler::GemHelper.install_tasks

require "rake/testtask"

Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
end

task default: :test
