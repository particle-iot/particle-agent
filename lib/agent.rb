class Agent
  attr_reader :options

  def initialize(options)
    @options = options
  end


  def run!
    loop do
      puts "doing work"
      sleep 5
    end
  end
end
