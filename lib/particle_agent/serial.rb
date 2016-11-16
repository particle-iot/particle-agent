require "particle_agent/config"
require "particle_agent/settings"

module ParticleAgent
  # CLI command to show the stdin/stdout
  class Serial
    CHARS = 4096

    attr_reader :settings
    def initialize(_options)
      @settings = Settings.new
    end

    def run!
      load_settings
      if streams_exist?
        connect_serial
      else
        no_device_error
      end
    end

    def load_settings
      settings.load
    end

    def streams_exist?
      device_id &&
        File.exist?(firmware_stdin_pipe_path) &&
        File.exist?(firmware_stdout_pipe_path)
    end

    def connect_serial
      loop do
        read_io = [$stdin, firmware_stdout_pipe]
        read_ready,_,_ = IO.select(read_io)

        case read_ready[0]
        when $stdin
          process_stdin
        when firmware_stdout_pipe
          process_firmware_stdout
        end
      end
    end

    def process_stdin
      str = $stdin.readpartial(CHARS)
      firmware_stdin_pipe.write str
    end

    def process_firmware_stdout
      str = firmware_stdout_pipe.readpartial(CHARS)
      $stdout.write str
    end

    def device_id
      (settings.values["devices"] || []).first
    end

    def firmware_stdin_pipe
      @firmware_stdin_pipe ||= File.open(firmware_stdin_pipe_path, 'w+')
    end

    def firmware_stdout_pipe
      @firmware_stdout_pipe ||= File.open(firmware_stdout_pipe_path, 'r+')
    end

    def firmware_stdin_pipe_path
      File.join device_path, Config.stdin_pipe_name
    end

    def firmware_stdout_pipe_path
      File.join device_path, Config.stdout_pipe_name
    end

    def device_path
      @device_path ||= File.join Config.devices_path, device_id
    end

    def no_device_error
      puts "No device configured. Run sudo particle-agent setup first"
    end
  end
end
