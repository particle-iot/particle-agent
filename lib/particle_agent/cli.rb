require "thor"
require "particle_agent/setup"

module ParticleAgent
  # Entry point for the Particle Pi command line interface
  class CLI < Thor
    desc "setup", "Connect your Raspberry Pi to the Particle Cloud"
    option :username
    option :password
    def setup
      Setup.new(options).run!
    end
  end
end