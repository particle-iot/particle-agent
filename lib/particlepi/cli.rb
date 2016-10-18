require "thor"
require "particlepi/setup"

module ParticlePi
  class CLI < Thor
    desc "setup", "Connect your Raspberry Pi to the Particle Cloud"
    option :username
    option :password
    def setup
      Setup.new(options).run!
    end
  end
end
