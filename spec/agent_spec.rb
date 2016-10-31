require_relative "spec_helper"
require "particlepi/agent"
require "fileutils"

describe ParticlePi::Agent do
  describe "firmware_paths" do
    def with_temp_run
      previous_run_path = ParticlePi::Config.run_path
      Dir.mktmpdir do |run_path|
        begin
          yield run_path
        ensure
          ParticlePi::Config.run_path = previous_run_path
        end
      end
    end

    it "returns empty when the devices directory doesn't exist" do
      with_temp_run do
        agent = ParticlePi::Agent.new
        actual = agent.firmware_paths

        expected = []
        assert_equal expected, actual
      end
    end

    it "finds all firmwares" do
      with_temp_run do |run_path|
        # Create some directory and regular files in the devices directory
        ParticlePi::Config.run_path = run_path
        device1_path = File.join run_path, "devices", "device1"
        FileUtils.mkdir_p device1_path
        device2_path = File.join run_path, "devices", "device2"
        FileUtils.mkdir_p device2_path
        regular_file_path = File.join run_path, "devices", "file"
        IO.write regular_file_path, "test"

        agent = ParticlePi::Agent.new
        actual = agent.firmware_paths

        expected = device1_path, device2_path
        assert_equal expected, actual
      end
    end
  end
end
