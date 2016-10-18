require "particlerb"
require "paint"
require "highline"
require "particlepi/spinner"

module ParticlePi
  class LoginFailedError < StandardError
  end

  class Setup
    attr_reader :username, :password
    attr_reader :token
    attr_reader :prompt
    def initialize(options)
      @user = options[:user]
      @password = options[:password]
      @prompt = HighLine.new
      @token = nil
    end

    def run!
      info "Let's connect your Raspberry Pi to the Particle Cloud!"
      prompt_credentials
      perform_login

      puts "You are now logged in with token #{token}"

    rescue LoginFailedError => e
      error "Wrong username or password"
      info "Don't have an account yet? Create one at https://login.particle.io"

    rescue Faraday::ClientError
      error "Network error. Check your internet connection and try again"
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

    def info(message)
      puts Paint[message, :blue, :bright]
    end

    def error(message)
      puts Paint[message, :red]
    end
  end
end
