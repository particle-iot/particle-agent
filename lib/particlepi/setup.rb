require "highline"
require "particlerb"
require "particlepi/spinner"
require "particlepi/settings"

module ParticlePi
  class LoginFailedError < StandardError
  end

  class Setup
    attr_reader :username, :password
    attr_reader :token
    attr_reader :device_id
    attr_reader :prompt
    attr_reader :settings
    def initialize(options)
      @user = options[:user]
      @password = options[:password]
      @prompt = HighLine.new
      @token = nil
      @device_id = nil
      @settings = Settings.new
    end

    def run!
      load_settings
      title "Let's connect your Raspberry Pi to the Particle Cloud!"
      if reenter_credentials
        prompt_credentials
        perform_login
        store_credentials
      end

      prompt_device_id
      save_device_id
      generate_device_key

      restart_agent
    rescue LoginFailedError => e
      error "Wrong username or password"

    rescue Faraday::ClientError
      error "Network error. Check your internet connection and try again"
    end

    def load_settings
      settings.load
    end

    def reenter_credentials
      username = settings.values["username"]
      if username
        prompt.say "\nYou are already logged in as #{Paint[username, :yellow, :bold]}."
        prompt.agree "Do you want to log in as a different user? " do |q|
          q.default = 'yes'
        end
      else
        info "Log in with your Particle account"
        info "Don't have an account yet? Create one at https://login.particle.io"
        true
      end
    end

    def prompt_credentials
      @username = prompt.ask("Email address: ") do |q|
        q.default = username
        q.responses[:ask_on_error] = :question
        q.validate =/@/
      end
      @password = prompt.ask("Password: ") do |q|
        q.default = password
        q.echo = false
      end
    end

    def perform_login
      Spinner.start "Loging in" do
        particle_token = Particle.login(username, password, expires_in: 0)
        @token = particle_token.id
      end
    rescue Particle::BadRequest => e
      raise LoginFailedError.new
    end

    def store_credentials
      settings.values["username"] = username
      settings.values["token"] = token
      settings.save
    end

    def prompt_device_id
      @device_id = prompt.ask "Enter the device ID you were given for this device: " do |q|
        q.validate = /^[0-9a-z]{24}$/
      end
    end

    def device_id_path
      File.join(ParticlePi.project_root, "settings/device_id.txt")
    end

    def save_device_id
      IO.write(device_id_path, device_id)
    end

    def key_path
      File.join(ParticlePi.project_root, "settings/device_key.der")
    end

    def generate_device_key
      system "openssl genrsa 1024 | openssl rsa -outform DER -out #{key_path}"
    end

    def restart_agent
      system "sudo service particlepi restart"
    end


    def title(message)
      prompt.say Paint[message, :blue, :bold]
    end

    def info(message)
      prompt.say message
    end

    def error(message)
      prompt.say Paint[message, :red]
    end
  end
end
