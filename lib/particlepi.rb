require "particlepi/version"

# ParticlePi
# An agent that runs the Particle firmware on the Raspberry Pi
module ParticlePi
  def self.project_root
    File.expand_path("../..", __FILE__)
  end
end
