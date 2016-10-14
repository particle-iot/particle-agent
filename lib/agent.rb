class Agent
  def run!(daemon)
    puts "Starting firmware"
    until daemon.quit?
      run_firmware
    end
    puts "Quitting gracefully"
  end

  private

  def run_firmware
    pid = Process.fork do
      Dir.chdir settings_path
      exec firmware_executable, *firmware_args
    end

    pid, status = Process.waitpid2(pid)
    puts "Firmware exited with status #{status}"

  end

  def settings_path
    File.expand_path("../../settings", __FILE__)
  end

  def firmware_executable
    File.expand_path("../../binaries/tinker", __FILE__)
  end

  def firmware_args
    ["-v", "70"]
  end
end
