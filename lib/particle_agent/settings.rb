require "json"
require "particle_agent/config"

module ParticleAgent
  # Load and save settings for the app
  class Settings
    attr_reader :path
    attr_reader :values
    def initialize(path = default_path)
      @path = path
      @values = {}
    end

    def load
      settings_str = IO.read(path)
      @values = JSON.parse(settings_str) unless settings_str.empty?
    rescue Errno::ENOENT
      # Ignore missing file
      @values = {}
    end

    def save
      settings_str = JSON.pretty_generate(values)
      ensure_directory_exists(path)
      IO.write(path, settings_str)
    end

    def default_path
      Config.settings_path
    end

    def ensure_directory_exists(filename)
      dirname = File.dirname(filename)
      FileUtils.mkdir_p(dirname, mode: 0o755) unless File.directory?(dirname)
    end
  end
end
