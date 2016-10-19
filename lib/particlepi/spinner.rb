require "whirly"
require "paint"

Paint.mode = 0 unless $stdout.tty?
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
