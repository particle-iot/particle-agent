require "thor"
require "particle_agent/setup"
require "particle_agent/logs"

module ParticleAgent
  # Entry point for the Particle Pi command line interface
  class CLI < Thor
    desc "setup", "Connect your Raspberry Pi to the Particle Cloud"
    option :api_endpoint
    option :server_key
    option :id
    def setup
      Setup.new(options).run!
    end

    desc "logs", "Stream the system logs like cloud connection and firmware crashes"
    option :lines,
      type: :numeric,
      default: 50,
      aliases: :n,
      desc: "Number of lines to show"
    option :all,
      type: :boolean,
      desc: "Print all log lines and exit"
    def logs
      Logs.new(options).run!
    end
  end
end
