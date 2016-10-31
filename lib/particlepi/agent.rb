require "particlepi/config"

module ParticlePi
  # The logic for the agent that monitor the firmware
  # Usually runs in the background as a daemon
  class Agent
    def run!(daemon)
      firmware_paths.each do |firmware_path|
        runner = FirmwareRunner.new(firmware_path)
        runner.run!
      end

      sleep 1 until daemon.quit?

      puts "Quitting agent gracefully"
    end

    def firmware_paths
      Dir.glob("#{Config.devices_path}/*")
         .select { |f| File.directory?(f) }
    end
  end
end
