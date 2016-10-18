require 'json'

module ParticlePi
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
    end

    def save
      settings_str = JSON.pretty_generate(values)
      IO.write(path, settings_str)
    end

    def default_path
      File.join(ParticlePi.project_root, "settings/particle.json")
    end
  end
end
