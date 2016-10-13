class Agent
  def run!(daemon)
    until daemon.quit
      puts "Doing work"
      sleep 5
    end
  end
end
