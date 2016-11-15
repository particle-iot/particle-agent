require_relative "spec_helper"

describe ParticleAgent::Config do
  it "finds the right path for tinker" do
    expected = File.expand_path("../../share/binaries/tinker", __FILE__)
    assert_equal expected, ParticleAgent::Config.tinker_path
  end

  it "finds the global share path" do
    expected = "/usr/share/particle"
    assert_equal expected, ParticleAgent::Config.share_path(true)
  end

  it "finds the global run path" do
    expected = "/var/lib/particle"
    assert_equal expected, ParticleAgent::Config.lib_path
  end
end
