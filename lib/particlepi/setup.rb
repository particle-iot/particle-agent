require "highline"
require "particlerb"
require "particlepi/spinner"
require "particlepi/settings"

module ParticlePi
  class LoginFailedError < StandardError
  end

  class KeyUpdateError < StandardError
  end

  class ClaimError < StandardError
  end

  # CLI command to set up the Rapsberry Pi as a Particle device
  class Setup
    attr_reader :username, :password
    attr_reader :token
    attr_reader :device_id
    attr_reader :name
    attr_reader :prompt
    attr_reader :settings
    def initialize(options)
      @user = options[:user]
      @password = options[:password]
      @prompt = HighLine.new
      @token = nil
      @device_id = nil
      @name = nil
      @settings = Settings.new
    end

    # TODO: refactor once I know what this command should be doing
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def run!
      load_settings
      title "Let's connect your Raspberry Pi to the Particle Cloud!\n"
      if reenter_credentials
        prompt_credentials
        perform_login
        save_credentials
      else
        auth_client
      end

      prompt_device_id
      save_device_id
      prompt_device_name
      save_device_name
      generate_device_key

      Spinner.show "Claiming the device to your Particle account" do
        publish_device_key
        restart_agent
        claim_device
        rename_device
      end

      info "Done! Go to #{color('https://build.particle.io', :link)} to flash code to your Raspberry Pi"
    rescue LoginFailedError => e
      error e.message

    rescue KeyUpdateError => e
      error "#{e.message}. Are you sure this device is not owned by another account?"

    rescue ClaimError => e
      error "#{e.message}. ==> The fix would be to ensure tinker is running."

    rescue Faraday::ClientError
      error "Network error. Check your internet connection and try again"
    end

    def load_settings
      settings.load
    end

    def reenter_credentials
      username = settings.values["username"]
      if username
        prompt.say "You are already logged in as #{color(username, :highlight)}."
        prompt.agree "Do you want to log in as a different user? " do |q|
          q.default = "yes"
        end
      else
        info "Log in with your Particle account"
        info "Don't have an account yet? Create one at #{color('https://login.particle.io', :link)}"
        true
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def prompt_credentials
      @username = prompt.ask("Email address: ") do |q|
        q.default = username
        q.responses[:ask_on_error] = :question
        q.validate = /@/
      end
      @password = prompt.ask("Password: ") do |q|
        q.default = password
        q.echo = false
      end
    end

    def perform_login
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

    def prompt_device_id
      prompt.say "For the alpha phase, you should have received a device ID for the Raspberry Pi"
      @device_id = prompt.ask "Device ID: " do |q|
        q.validate = /^[0-9a-z]{24}$/
        q.default = IO.read(device_id_path).chomp if File.exist?(device_id_path)
      end
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

    def device_id_path
      File.join(ParticlePi.project_root, "settings/device_id.txt")
    end

    def save_device_id
      IO.write(device_id_path, device_id + "\n")
    end

    def key_path
      File.join(ParticlePi.project_root, "settings/device_key.der")
    end

    def public_key_path
      File.join(ParticlePi.project_root, "settings/device_key.pub.pem")
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
      system "sudo service particlepi restart"
    end

    def claim_device(tries = 5)
      Particle.device(device_id).claim
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
