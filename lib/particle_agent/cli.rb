require "thor"
require "particle_agent/setup"
require "particle_agent/logs"
require "particle_agent/serial"
require "particle_agent/service"

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

    desc "serial", "Show the output of Serial.print in the running firmware"
    def serial
      Serial.new(options).run!
    end

    desc "start", "Start the agent service"
    def start
      Service.new(options).start!
    end

    desc "stop", "Stop the agent service"
    def stop
      Service.new(options).stop!
    end

    desc "restart", "Stop and start the agent service"
    def restart
      Service.new(options).restart!
    end

    desc "status", "Shows if the agent and firmware are running"
    def status
      Service.new(options).status!
    end
  end
end
