require "particlerb"
require "paint"
require "highline"
require "particlepi/spinner"
require "particlepi/settings"

module ParticlePi
  class LoginFailedError < StandardError
  end

  class Setup
    attr_reader :username, :password
    attr_reader :token
    attr_reader :prompt
    attr_reader :settings
    def initialize(options)
      @user = options[:user]
      @password = options[:password]
      @prompt = HighLine.new
      @token = nil
      @settings = Settings.new
    end

    def run!
      load_settings
      info "Let's connect your Raspberry Pi to the Particle Cloud!"
      if reenter_credentials
        prompt_credentials
        perform_login
        store_credentials
      end

    rescue LoginFailedError => e
      error "Wrong username or password"
      info "Don't have an account yet? Create one at https://login.particle.io"

    rescue Faraday::ClientError
      error "Network error. Check your internet connection and try again"
    end

    def load_settings
      settings.load
    end

    def reenter_credentials
      username = settings.values["username"]
      if username
        prompt.choose do |menu|
          menu.prompt = "You are already logged in as #{Paint[username, :yellow]}. Do you want to log in as a different user?"
          menu.choices(:yes) { true }
          menu.choices(:no) { false }
        end
      else
        true
      end
    end

    def prompt_credentials
      @username = prompt.ask("Email address: ") do |q|
        q.default = username
        q.validate =/@/
      end
      @password = prompt.ask("Password: ") do |q|
        q.default = password
        q.echo = false
      end
    end

    def perform_login
      Spinner.start do
        @token = Particle.login(username, password, expires_in: 0)
      end
    rescue Particle::BadRequest => e
      raise LoginFailedError.new
    end

    def store_credentials
      settings.values["username"] = username
      settings.values["token"] = token
      settings.save
    end

    def info(message)
      prompt.ask Paint[message, :blue, :bold]
    end

    def error(message)
      prompt.ask Paint[message, :red]
    end
  end
end
