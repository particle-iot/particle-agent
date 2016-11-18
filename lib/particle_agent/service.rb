module ParticleAgent
  # Shortcuts to interact with the service
  class Service
    def initialize(_options)
    end

    def start!
      service "start"
    end

    def stop!
      service "stop"
    end

    def restart!
      service "restart"
    end

    def status!
      service "status"
    end

    def service(command)
      system "sudo service particle-agent #{command}"
    end
  end
end
