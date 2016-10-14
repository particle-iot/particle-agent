require_relative 'spec_helper'
require 'daemon'
require 'tempfile'

describe Daemon do
  it "runs in the foreground without options" do
    daemon = Daemon.new
    run = false

    daemon.run! { run = true }

    assert_equal true, run
  end

  it "runs if the pidfile doesn't exist" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.close
    daemon = Daemon.new(pidfile: pidfile.path)
    run = false

    daemon.run! { run = true }

    assert_equal true, run
  end

  it "doesn't run if the pidfile exists" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.write Process.pid
    pidfile.close
    daemon = Daemon.new(pidfile: pidfile.path)
    daemon.exit_with_error = lambda { |message| raise message }

    err = assert_raises RuntimeError do
      daemon.run!
    end

    assert_match (/The agent is already running/), err.message
  end

  it "writes a pidfile" do
    pidfile = Tempfile.new('test-daemon')
    pidfile.close
    daemon = Daemon.new(pidfile: pidfile.path)

    daemon.run!

    pid = IO.read(pidfile.path)
    assert_equal Process.pid, pid.to_i
  end

  it "daemonizes" do
    # Use a pipe to communicate with daemonized process
    rd, wr = IO.pipe
    daemon = Daemon.new(daemonize: true)

    # fork to avoid exiting the current process
    fork do
      daemon.run! do
        rd.close
        wr.write "Done"
        wr.close
      end
    end

    wr.close
    assert_equal "Done", rd.read
  end

  it "traps signals and quits the subtask" do
    pid_rd, pid_wr = IO.pipe
    rd, wr = IO.pipe
    daemon = Daemon.new(daemonize: true)

    fork do
      daemon.run! do |d|
        pid_rd.close
        pid_wr.write Process.pid
        pid_wr.close
        rd.close

        until d.quit?
          sleep 0.01
        end
        wr.write "Quit"
      end
    end

    pid_wr.close
    daemon_pid = pid_rd.read.to_i
    Process.kill("QUIT", daemon_pid)

    wr.close
    assert_equal "Quit", rd.read
  end

  it "logs to a file" do
    logfile = Tempfile.new('log-daemon')
    logfile.close

    rd, wr = IO.pipe
    daemon = Daemon.new(daemonize: true, logfile: logfile)

    fork do
      daemon.run! do |d|
        puts "This is a log"
        rd.close
        wr.write "Done"
      end
    end

    wr.close
    rd.read

    log = IO.read(logfile.path)
    assert_equal "This is a log\n", log
  end

end
