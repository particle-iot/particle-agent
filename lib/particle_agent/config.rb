module ParticleAgent
  # Common paths for the entire app
  module Config
    # Where the settings JSON is stored
    def self.settings_path
      File.join run_path, "settings.json"
    end

    # Each subdirectory in this path holds one device firmware and keys
    def self.devices_path
      File.join run_path, "devices"
    end

    # The name of the ELF executable for the device firmware
    def self.firmware_executable
      "firmware.bin"
    end

    # The name of the file where the Over-The-Air update firmware is saved
    def self.ota_executable
      "output.bin"
    end

    # The named pipe that will be connected to stdin for the device
    def self.stdin_pipe_name
      "stdin"
    end

    # The named pipe that will be connected to stdout for the device
    def self.stdout_pipe_name
      "stdout"
    end

    # The path of the default binary
    def self.tinker_path
      File.join share_path, "binaries/tinker"
    end

    # The path to the server public key
    def self.server_key_path
      File.join share_path, "keys/server_key.der"
    end

    # The product ID for the Raspberry Pi
    def self.product_id
      31
    end

    # The path where runtime configuration like user apps and keys are kept
    # Can be overwritten for tests
    @run_path = "/var/lib/particle"
    def self.run_path
      @run_path
    end

    def self.run_path=(path)
      @run_path = path
    end

    # The path where data files for the app are kept
    # Either share/ in this gem or /usr/share/particle if the package is installed
    def self.share_path(force_global = false)
      if !force_global && File.exist?(share_gem_path)
        share_gem_path
      else
        share_global_path
      end
    end

    def self.share_gem_path
      File.expand_path("../../share", File.dirname(__FILE__))
    end

    def self.share_global_path
      "/usr/share/particle"
    end
  end
end
