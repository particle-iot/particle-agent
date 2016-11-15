require "fileutils"
require "particle_agent/config"

module ParticleAgent
  # CLI command to show the system logs
  class Logs
    attr_reader :log_lines
    attr_reader :print_all
    def initialize(options)
      @logs_path = options[:path]
      @log_lines = options[:lines]
      @print_all = options[:all]
    end

    def run!
      system "#{print_command} #{logs_path}"
    end

    def print_command
      if print_all
        "cat"
      else
        "tail -f -n #{log_lines}"
      end
    end

    def logs_path
      @logs_path || Config.logs_path
    end
  end
end
