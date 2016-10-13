class Agent
  attr_reader :options

  def initialize(options)
    @options = options
    expand_directories
  end


  def run!
    loop do
      puts "doing work"
      sleep 5
    end
  end

  def daemonize?
    options[:daemonize]
  end

  def logfile
    options[:logfile]
  end

  def pidfile
    options[:pidfile]
  end

  private

  # Daemonize will change working directory so expand relative paths now
  def expand_directories
    options[:logfile] = File.expand_path(logfile) if logfile
    options[:pidfile] = File.expand_path(pidfile) if pidfile
  end
end
