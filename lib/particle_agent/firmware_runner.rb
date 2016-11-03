require "particle_agent/config"
require "fileutils"

module ParticleAgent
  # Responsible for running one firmware executable
  class FirmwareRunner
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def run!(daemon)
      until daemon.quit?
        apply_ota
        if firmware_exist?
          create_pipes
          run_firmware

          puts "Quitting firmware gracefully"
        else
          sleep 1
        end
      end
    end

    private

    def apply_ota
      if ota_exist?
        FileUtils.chmod 0o744, ota_executable_path
        FileUtils.mv ota_executable_path, firmware_executable_path
      end
    end

    def firmware_exist?
      File.exist? firmware_executable_path
    end

    def ota_exist?
      File.exist? ota_executable_path
    end

    def stdin_pipe
      File.join path, Config.stdin_pipe_name
    end

    def stdout_pipe
      File.join path, Config.stdout_pipe_name
    end

    def create_pipes
      system("mkfifo #{stdin_pipe}") unless File.exist?(stdin_pipe)
      system("mkfifo #{stdout_pipe}") unless File.exist?(stdout_pipe)
    end

    def run_firmware
      pid = Process.spawn(
        firmware_env,
        firmware_executable_path,
        *firmware_args,
        in: [stdin_pipe, "r+"],
        out: [stdout_pipe, "w+"],
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
  end
end
