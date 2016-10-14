# Put the current process in the background, manage pid file and
# redirect output to a log file
#
# Adapted from https://github.com/jakesgordon/ruby-sample-daemon
# Copyright (c) 2014, 2015, 2016, Jake Gordon, licensed under the MIT license.
require 'fileutils'

class Daemon
  attr_reader :options
  attr_accessor :exit_with_error

  def initialize(options = {})
    @options = options
    expand_directories
    @quit = false

    # Allow swapping out the exit behavior for testing
    @exit_with_error = lambda do |message|
      $stderr.puts message
      exit 1
    end
  end

  def run!
    check_pid
    daemonize if daemonize?
    write_pid
    trap_signals

    if logfile
      redirect_output
    elsif daemonize?
      suppress_output
    end

    # Start the worker, passing the daemon install to be able to exit
    # gracefully by checking daemon.quit?
    yield(self) if block_given?
  end

  def quit!
    @quit = true
  end

  def quit?
    @quit
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

  def write_pid
    return unless pidfile
    begin
      File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) do |f|
        f.write Process.pid
      end
      at_exit { delete_pid }
    rescue Errno::EEXIST
      check_pid
      retry
    end
  end

  def delete_pid
    return unless pidfile
    File.delete(pidfile) if File.exist?(pidfile)
  end

  def check_pid
    return unless pidfile
    case pid_status(pidfile)
    when :running, :not_owned
      exit_with_error.call "The agent is already running. Check #{pidfile}"
    when :dead
      File.delete(pidfile)
    end
  end

  def pid_status(pidfile)
    return :exited unless File.exist?(pidfile)

    pid = ::File.read(pidfile).to_i
    return :dead if pid == 0
    # check process status
    Process.kill(0, pid)
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end

  def daemonize
    exit if fork
    Process.setsid
    exit if fork
    Dir.chdir "/"
  end

  def redirect_output
    FileUtils.mkdir_p(File.dirname(logfile), :mode => 0755)
    FileUtils.touch logfile
    File.chmod(0644, logfile)
    $stderr.reopen(logfile, 'a')
    $stdout.reopen($stderr)
    $stdout.sync = $stderr.sync = true
  end

  def suppress_output
      $stderr.reopen('/dev/null', 'a')
      $stdout.reopen($stderr)
  end

  def trap_signals
    [:QUIT, :TERM, :INT].each do |signal|
      trap signal do
        unless @quit
          puts "Got signal to quit gracefully"
          # Tell main loop to stop
          @quit = true
          # Kill subprocesses
          Process.kill("QUIT", 0)
        end
      end
    end
  end
end
