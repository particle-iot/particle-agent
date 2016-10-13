class Agent
  def run!(daemon)
    puts "Starting"
    until daemon.quit
      puts "Doing work"
      sleep 5
    end
    puts "Quitting gracefully"
  end
end
