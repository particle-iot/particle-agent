require "particle_agent/config"
require "particle_agent/firmware_runner"
require "particle_agent/settings"

module ParticleAgent
  # The logic for the agent that monitor the firmware
  # Usually runs in the background as a daemon
  class Agent
    attr_reader :settings

    def initialize
      @settings = Settings.new
    end

    def run!(daemon)
      load_settings

      puts "Starting agent"

      start_firmware_runners daemon

      sleep 1 until daemon.quit?

      puts "Quitting agent gracefully"
    end

    def load_settings
      settings.load
    end

    def start_firmware_runners(daemon)
      puts "No firmware to run." if firmware_paths.empty?

      firmware_paths.map do |firmware_path|
        Thread.new do
          runner = FirmwareRunner.new(firmware_path)
          runner.run!(daemon)
        end
      end.each(&:join)
    end

    def active_devices
      settings.values["devices"] || []
    end

    def firmware_paths
      active_devices
        .map { |id| File.join Config.devices_path, id }
        .select { |f| File.directory?(f) }
    end
  end
end
