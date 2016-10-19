require_relative 'spec_helper'
require 'particlepi/daemon'
require 'tempfile'

describe ParticlePi::Daemon do
  it "runs in the foreground without options" do
    daemon = ParticlePi::Daemon.new
    run = false

    daemon.run! { run = true }

    assert_equal true, run
  end

  it "runs if the pidfile doesn't exist" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.close
    daemon = ParticlePi::Daemon.new(pidfile: pidfile.path)
    run = false

    daemon.run! { run = true }

    assert_equal true, run
  end

  it "doesn't run if the pidfile exists" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.write Process.pid
    pidfile.close
    daemon = ParticlePi::Daemon.new(pidfile: pidfile.path)
    daemon.exit_with_error = lambda { |message| raise message }

    err = assert_raises RuntimeError do
      daemon.run!
    end

    assert_match (/The agent is already running/), err.message
  end

  it "writes the pid to a pidfile" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.close
    daemon = ParticlePi::Daemon.new(pidfile: pidfile.path)

    daemon.run!

    pid = IO.read(pidfile.path)
    assert_equal Process.pid, pid.to_i
  end

  it "deletes the pid file at exit" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.close
    daemon = ParticlePi::Daemon.new(pidfile: pidfile.path)

    fork do
      daemon.run!
    end
    Process.wait

    assert_equal false, File::exist?(pidfile.path)
  end

  it "daemonizes" do
    # Use a pipe to communicate with daemonized process
    rd, wr = IO.pipe
    daemon = ParticlePi::Daemon.new(daemonize: true)

    # fork to avoid exiting the current process
    fork do
      daemon.run! do
        rd.close
        wr.write "Done"
        wr.close
      end
    end

    Process.wait
    wr.close
    assert_equal "Done", rd.read
  end

  it "traps signals and quits the subtask" do
    pid_rd, pid_wr = IO.pipe
    rd, wr = IO.pipe
    daemon = ParticlePi::Daemon.new(daemonize: true)

    fork do
      daemon.run! do |d|
        pid_rd.close
        pid_wr.write Process.pid
        pid_wr.close

        # Subtask that doen't quit until it receives a signal
        fork do
          subtask_quit = false
          
          trap(:QUIT) { subtask_quit = true }
          until subtask_quit
            sleep 0.01
          end

          rd.close
          wr.write "Quit"
        end

        until d.quit?
          sleep 0.01
        end
        Process.wait
      end
    end

    pid_wr.close
    daemon_pid = pid_rd.read.to_i
    Process.kill("QUIT", daemon_pid)

    wr.close
    assert_equal "Quit", rd.read
    Process.wait
  end

  it "logs to a file" do
    logfile = Tempfile.new('log-daemon')
    logfile.close

    rd, wr = IO.pipe
    daemon = ParticlePi::Daemon.new(daemonize: true, logfile: logfile)

    fork do
      daemon.run! do |d|
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
