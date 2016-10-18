require "whirly"

Whirly.configure spinner: "dots"

module ParticlePi
  class Spinner
    def self.start(&block)
      Whirly.start &block
    end
  end
end
