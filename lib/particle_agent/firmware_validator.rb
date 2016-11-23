module ParticleAgent
  # Check if a firmware executable is valid for the current platform
  class FirmwareValidator
    def initialize(path)
      @path = path
    end
    attr_reader :path

    def valid?
      !!file_type.match(raspberry_pi_executable)
    end

    def file_type
      `file "#{path}"`
    end

    def raspberry_pi_executable
      /ELF 32-bit LSB executable, ARM/
    end
  end
end

