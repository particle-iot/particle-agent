require_relative "spec_helper"
require "particle_agent/daemon"
require "tempfile"

describe ParticleAgent::Daemon do
  it "runs in the foreground without options" do
    daemon = ParticleAgent::Daemon.new
    run = false

    daemon.run! { run = true }

    assert_equal true, run
  end

  it "runs if the pidfile doesn't exist" do
    pidfile = Tempfile.new("test-daemon")
    pidfile.close
    daemon = ParticleAgent::Daemon.new(pidfile: pidfile.path)
    run = false

    daemon.run! { run = true }

    assert_equal true, run
  end

  it "doesn't run if the pidfile exists" do
    pidfile = Tempfile.new("test-daemon")
    pidfile.write Process.pid
    pidfile.close
    daemon = ParticleAgent::Daemon.new(pidfile: pidfile.path)
    daemon.exit_with_error = ->(message) { raise message }

    err = assert_raises RuntimeError do
      daemon.run!
    end

    assert_match(/The agent is already running/, err.message)
  end

  it "writes the pid to a pidfile" do
    pidfile = Tempfile.new("test-daemon")
    pidfile.close
    daemon = ParticleAgent::Daemon.new(pidfile: pidfile.path)

    daemon.run!

    pid = IO.read(pidfile.path)
    assert_equal Process.pid, pid.to_i
  end

  it "deletes the pid file at exit" do
    pidfile = Tempfile.new("test-daemon")
    pidfile.close
    daemon = ParticleAgent::Daemon.new(pidfile: pidfile.path)

    fork do
      daemon.run!
    end
    Process.wait

    assert_equal false, File.exist?(pidfile.path)
  end

  it "daemonizes" do
    # Use a pipe to communicate with daemonized process
    rd, wr = IO.pipe
    daemon = ParticleAgent::Daemon.new(daemonize: true)

    # fork to avoid exiting the current process
    fork do
      daemon.run! do
        wr.puts Process.getpgrp
      end
    end
    Process.wait

    this_process_group = Process.getpgrp
    daemon_process_group = rd.gets.to_i
    refute_equal this_process_group, daemon_process_group
  end

  it "traps signals and interrupts the subtask" do
    rd, wr = IO.pipe
    daemon = ParticleAgent::Daemon.new(daemonize: true)

    fork do
      daemon.run! do |d|
        wr.puts Process.pid

        # Subtask that doen't quit until it receives a signal
        fork do
          subtask_quit = false

          trap(:INT) { subtask_quit = true }

          wr.puts "Start"
          sleep 0.01 until subtask_quit
          wr.puts "Quit"
        end

        sleep 0.01 until d.quit?
        Process.wait
      end
    end
    Process.wait

    daemon_pid = rd.gets.to_i
    assert_equal "Start", rd.gets.chomp
    Process.kill(:TERM, daemon_pid)

    assert_equal "Quit", rd.gets.chomp
  end

  it "force quits subtasks after a delay" do
    rd, wr = IO.pipe
    daemon = ParticleAgent::Daemon.new(daemonize: true, quit_delay: 0.01)

    fork do
      daemon.run! do |d|
        wr.puts Process.pid

        # Subtask that doesn't quit cleanly
        fork do
          trap(:INT) {}
          trap(:TERM, "DEFAULT")

          wr.puts "Start"
          loop do
            sleep 1
          end
        end

        sleep 0.01 until d.quit?
        Process.wait
        wr.puts "Subtask quit"
      end
    end
    Process.wait

    daemon_pid = rd.gets.to_i
    assert_equal "Start", rd.gets.chomp
    Process.kill(:TERM, daemon_pid)

    assert_equal "Subtask quit", rd.gets.chomp
  end

  it "logs to a file" do
    logfile = Tempfile.new("log-daemon")
    logfile.close

    rd, wr = IO.pipe
    daemon = ParticleAgent::Daemon.new(daemonize: true, logfile: logfile)

    fork do
      daemon.run! do
        puts "This is a log"
        rd.close
        wr.write "Done"
      end
    end

    wr.close
    rd.read

    Process.wait
    log = IO.read(logfile.path)
    assert_equal "This is a log\n", log
  end
end
