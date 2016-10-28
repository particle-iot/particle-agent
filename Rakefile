#!/usr/bin/env rake

require "bundler"
Bundler::GemHelper.install_tasks

default_tasks = []

require "rake/testtask"
default_tasks << Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
end

unless ENV["CI"]
  require "rubocop/rake_task"
  default_tasks << RuboCop::RakeTask.new(:rubocop)
end

task default: default_tasks.map(&:name)
