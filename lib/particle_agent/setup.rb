require "highline"
require "fileutils"
require "particlerb"
require "particle_agent/spinner"
require "particle_agent/config"
require "particle_agent/settings"
require "particle_agent/string_patches"

module ParticleAgent
  class LoginFailedError < StandardError
  end

  class KeyUpdateError < StandardError
  end

  class ClaimError < StandardError
  end

  class ProvisioningError < StandardError
  end

  # CLI command to set up the Rapsberry Pi as a Particle device
  # rubocop:disable Metrics/ClassLength
  class Setup
    attr_reader :custom_server_key_path
    attr_reader :username, :password
    attr_reader :token
    attr_reader :device_id
    attr_reader :name
    attr_reader :prompt
    attr_reader :settings
    def initialize(options)
      configure_client(options)
      @custom_server_key_path = options[:server_key]
      @device_id = options[:id]
      @prompt = HighLine.new
      @token = nil
      @name = nil
      @settings = Settings.new
    end

    # TODO: refactor once I know what this command should be doing
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def run!
      load_settings
      title "Let's connect your Raspberry Pi to the Particle Cloud!\n"
      if keep_credentials
        auth_client
        restore_device_id
      else
        perform_login
        save_credentials
      end

      ensure_device_id
      ensure_device_path_exists
      save_device_id
      prompt_device_name
      save_device_name
      generate_device_key
      ensure_server_key_exists
      copy_tinker_firmware

      Spinner.show "Claiming the device to your Particle account" do
        publish_device_key
        restart_agent
        claim_device
        rename_device
      end

      post_install_message
    rescue KeyUpdateError => e
      error "#{e.message}. Are you sure this device is not owned by another account?"

    rescue ClaimError => e
      error "Error claiming the device. #{e.message}"

    rescue ProvisioningError => e
      error "Error getting a device ID. #{e.message}"

    rescue Particle::Error => e
      error "Particle cloud error. #{e.short_message}"

    rescue Faraday::ClientError
      error "Network error. Check your internet connection and try again"
    end

    def configure_client(options)
      Particle.api_endpoint = options[:api_endpoint] if options[:api_endpoint]
    end

    def load_settings
      settings.load
    end

    def keep_credentials
      username = settings.values["username"]
      if username
        prompt.say "You are already logged in as #{color(username, :highlight)}."
        prompt.agree "Do you want to stay logged in as this user? " do |q|
          q.default = "yes"
        end
      else
        info "Log in with your Particle account"
        info "Don't have an account yet? Create one at #{color('https://login.particle.io', :link)}"
        false
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def perform_login
      prompt_credentials
      send_credentials
    rescue LoginFailedError => e
      error e.message
      retry
    end

    def prompt_credentials
      @username = prompt.ask("Email address: ") do |q|
        q.responses[:ask_on_error] = :question
        q.validate = /@/
      end
      @password = prompt.ask("Password: ") do |q|
        q.echo = false
      end
    end

    def send_credentials
      Spinner.show "Logging in" do
        particle_token = Particle.login(username, password, expires_in: 0)
        @token = particle_token.id
      end
    rescue Particle::BadRequest
      raise LoginFailedError, "Wrong username or password"
    end

    def save_credentials
      settings.values["username"] = username
      settings.values["token"] = token
      settings.save
    end

    def auth_client
      Particle.access_token = settings.values["token"]
    end

    def restore_device_id
      @device_id ||= existing_device_id
    end

    def ensure_device_id
      @device_id ||= provision_device_id
    end

    def existing_device_id
      (settings.values["devices"] || []).first
    end

    def provision_device_id
      device = Particle.provision_device product_id: Config.product_id
      device.id
    rescue Particle::Forbidden => e
      raise ProvisioningError, e.short_message
    end

    def prompt_device_name
      prompt.say "How do you want your device to be labeled in the Particle tools?"
      @name = prompt.ask "Name: " do |q|
        q.default = settings.values["name"] || "pi"
      end
    end

    def save_device_name
      settings.values["name"] = name
      settings.save
    end

    def save_device_id
      IO.write(device_id_path, device_id + "\n")
      settings.values["devices"] = [device_id]
      settings.save
    end

    def ensure_device_path_exists
      FileUtils.mkdir_p(device_path, mode: 0o700) unless File.directory?(device_path)
    end

    def ensure_server_key_exists
      FileUtils.cp device_server_key_path, server_key_path unless File.exist?(server_key_path)
    end

    def copy_tinker_firmware
      FileUtils.install tinker_executable_path, firmware_executable_path
    end

    def device_id_path
      File.join device_path, "device_id.txt"
    end

    def key_path
      File.join device_path, "device_key.der"
    end

    def public_key_path
      File.join device_path, "device_key.pub.pem"
    end

    def firmware_executable_path
      File.join device_path, Config.firmware_executable
    end

    def server_key_path
      File.join device_path, "server_key.der"
    end

    def device_server_key_path
      custom_server_key_path || default_server_key_path
    end

    def default_server_key_path
      Config.server_key_path
    end

    def device_path
      @device_path ||= File.join Config.devices_path, device_id
    end

    def tinker_executable_path
      Config.tinker_path
    end

    def generate_device_key
      system "openssl genrsa 1024 | openssl rsa -outform DER -out #{key_path}"
      system "openssl rsa -inform DER -in #{key_path} -pubout -outform PEM -out #{public_key_path}"
    end

    def publish_device_key
      public_key = IO.read(public_key_path)
      Particle.device(device_id).update_public_key(public_key)
    rescue Particle::Forbidden
      raise KeyUpdateError, "Could not update keys for this device"
    end

    def restart_agent
      system "sudo service particle-agent restart"
    end

    def claim_device(tries = 5)
      Particle.device(device_id).claim

    rescue Particle::Forbidden
      # FIXME: the cloud returns an error when trying to claim your own device
      # So just ignore the error for now
      return
    rescue Particle::Error
      tries -= 1
      unless tries.zero?
        sleep 1
        retry
      end

      raise ClaimError, "Could not claim the device to your account"
    end

    def rename_device
      Particle.device(device_id).rename(name)
    end

    def post_install_message
      info <<-MESSAGE.unindent
        Done! Your Raspberry Pi is now connected to the #{color('Particle Cloud', :title)}.

        Your Raspberry Pi is running the default Particle app called #{color('Tinker', :highlight)}.
        #{color('Tinker', :highlight)} allows you to toggle pins with the Particle Mobile App.
          #{color('https://docs.particle.io/guide/getting-started/tinker/raspberry-pi/', :link)}

        When you are ready to write your own apps, check out the code examples.
          #{color('https://docs.particle.io/guide/getting-started/examples/raspberry-pi/', :link)}

        For more details about the Particle on Raspberry Pi, run:
          #{color('sudo particle-agent help', :command)}
          #{color('https://docs.particle.io/reference/particle-agent/', :link)}
      MESSAGE
    end

    def title(message)
      prompt.say color(message, :title)
    end

    def info(message)
      prompt.say message
    end

    def error(message)
      prompt.say color(message, :error)
    end

    def color(text, color_name)
      prompt.color text, color_name
    end
  end
end
# rubocop:enable Metrics/ClassLength
