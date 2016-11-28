require "particle_agent/config"
require "particle_agent/firmware_validator"
require "fileutils"

module ParticleAgent
  # Responsible for running one firmware executable
  class FirmwareRunner
    # N crashes in T seconds before safe mode
    CRASHES_BEFORE_SAFE_MODE = 5
    TIME_BEFORE_SAFE_MODE = 30

    attr_reader :path
    attr_reader :exit_times

    def initialize(path)
      @path = path
      @exit_times = []
    end

    def run!(daemon)
      until daemon.quit?
        apply_ota
        if firmware_exist?
          create_pipes
          run_firmware

          puts "Quitting firmware gracefully"
          check_safe_mode
        else
          sleep 1
        end
      end
    end

    private

    def apply_ota
      return unless ota_exist?
      return unless ota_valid?
      FileUtils.chmod 0o744, ota_executable_path
      FileUtils.mv ota_executable_path, firmware_executable_path
    end

    def firmware_exist?
      File.exist? firmware_executable_path
    end

    def ota_exist?
      File.exist? ota_executable_path
    end

    def ota_valid?
      FirmwareValidator.new(ota_executable_path).valid?
    end

    def stdin_pipe_path
      File.join path, Config.stdin_pipe_name
    end

    def stdout_pipe_path
      File.join path, Config.stdout_pipe_name
    end

    def create_pipes
      system("mkfifo #{stdin_pipe_path}") unless File.exist?(stdin_pipe_path)
      system("mkfifo #{stdout_pipe_path}") unless File.exist?(stdout_pipe_path)
    end

    def run_firmware
      pid = Process.spawn(
        firmware_env,
        firmware_executable_path,
        *firmware_args,
        in: [stdin_pipe_path, "r+"],
        out: [stdout_pipe_path, "w+"],
        # stderr is shared with the agent process
        chdir: settings_path
      )

      _pid, status = Process.waitpid2(pid)
      puts "Firmware exited with status #{status}"
    end

    def settings_path
      path
    end

    def firmware_env
      {}
    end

    def firmware_executable_path
      File.join path, Config.firmware_executable
    end

    def ota_executable_path
      File.join path, Config.ota_executable
    end

    def firmware_args
      ["-v", "70"]
    end

    def check_safe_mode
      # Keep last N firmware exit times
      exit_times.unshift Time.now
      exit_times.slice! CRASHES_BEFORE_SAFE_MODE..-1

      # N firmware crashes within N seconds
      oldest_exit = exit_times[CRASHES_BEFORE_SAFE_MODE - 1]
      if oldest_exit && Time.now - oldest_exit < TIME_BEFORE_SAFE_MODE
        apply_safe_mode
      end
    end

    def apply_safe_mode
      puts "Entering safe mode because firmware exited too many times in a row. Reverting to Tinker"
      FileUtils.cp tinker_executable_path, firmware_executable_path
    end

    def tinker_executable_path
      Config.tinker_path
    end
  end
end
