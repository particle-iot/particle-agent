require "thor"
require "particle_agent/setup"

module ParticleAgent
  # Entry point for the Particle Pi command line interface
  class CLI < Thor
    desc "setup", "Connect your Raspberry Pi to the Particle Cloud"
    option :api_endpoint
    option :server_key
    def setup
      Setup.new(options).run!
    end
  end
end
