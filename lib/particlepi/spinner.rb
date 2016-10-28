require "whirly"
require "highline"
require "particlepi/color_scheme"

HighLine.color_scheme = ParticlePi::ColorScheme.new
Whirly.configure spinner: "dots", color: false

module ParticlePi
  class Spinner
    def self.start(message = nil, &block)
      Whirly.start status: message, &block
    end

    def self.status=(message)
      Whirly.status = message
    end
  end
end
