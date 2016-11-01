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

desc "Remove packaging artifacts"
task :clean do
  sh "rm -rf pkg"
end

task package: :build do
  path_no_rbenv = ENV["PATH"].split(":").select { |p| !p.match(/rbenv/) }.join(":")
  sh "cd pkg && env PATH=#{path_no_rbenv} gem2deb -p particle-agent *.gem"
end

task default: default_tasks.map(&:name)
