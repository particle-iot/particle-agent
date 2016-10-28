require "particlepi"

module ParticlePi
  # The logic for the agent that monitor the firmware
  # Usually runs in the background as a daemon
  class Agent
    def run!(daemon)
      create_pipes
      puts "Starting firmware"

      run_firmware until daemon.quit?

      puts "Quitting gracefully"
    end

    private

    def stdin_pipe
      "/var/run/particlepi-stdin"
    end

    def stdout_pipe
      "/var/run/particlepi-stdout"
    end

    def create_pipes
      system("mkfifo #{stdin_pipe}") unless File.exist?(stdin_pipe)
      system("mkfifo #{stdout_pipe}") unless File.exist?(stdout_pipe)
    end

    def run_firmware
      pid = Process.spawn(
        firmware_env,
        firmware_executable,
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
      File.join(ParticlePi.project_root, "settings")
    end

    def firmware_env
      {}
    end

    def firmware_executable
      File.join(ParticlePi.project_root, "binaries/tinker")
    end

    def firmware_args
      ["-v", "70"]
    end
  end
end
