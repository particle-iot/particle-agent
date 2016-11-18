require "whirly"
require "highline"
require "particle_agent/color_scheme"

HighLine.color_scheme = ParticleAgent::ColorScheme.new
Whirly.configure spinner: "dots", color: false

module ParticleAgent
  # Show a spinning icon on the terminal during a long operation
  class Spinner
    def self.show(message = nil, &block)
      Whirly.start status: message, &block
    ensure
      Whirly.stop
    end

    def self.status=(message)
      Whirly.status = message
    end
  end
end
