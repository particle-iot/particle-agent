require_relative 'spec_helper'
require 'daemon'

# How to test this bad boy :-S
describe Daemon do
  describe "pid file" do
    pidfile = "/tmp/test-agent.pid"
    it "didn't leave a pid file from a previous run" do
      File.exist?(pidfile).must_equal false
    end

    it "creates the pid file" do
      File.delete(pidfile) if File.exist?(pidfile)
      agent = Daemon.new(pidfile: pidfile)

      agent.run!

      File.exist?(pidfile).must_equal true
    end
  end
end
