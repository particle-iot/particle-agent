# Particle Agent [![Build Status](https://travis-ci.org/spark/particle-agent.svg?branch=master)](https://travis-ci.org/spark/particle-agent)

This program supervises the Particle firmware executable running on
Raspberry Pi.

## Installing

Install the particle-agent Debian package by running this command on
your Raspberry Pi:

```
bash <( curl -sL https://particle.io/install-pi )
```

## Architecture

Particle Agent is a Ruby application. The logic lives inside <lib>

The Agent service is an executable that runs as a background service (daemon).
The agent service executable is <bin/particle-agent-service> and does things
like command line parsing. It delegates to the [Daemon
class](lib/particle_agent/daemon.rb) to manage a PID file, a log file
and fork the process to the background.

The logic for the agent is in the [Agent
class](lib/particle_agent/agent.rb). It finds which firmware executables
should run and runs them in their own process, restarting them if they
stop.

The service description for the Agent service is a System V init script in
<debian/particle-agent.init>.


## Manually Installing the service

FIXME: These instructions may not apply anymore

```
sudo cp debian/particle-agent.init /etc/init.d
sudo ln -s $PWD/bin/particle-agent-service /usr/bin/particle-agent-service
sudo insserv particle-agent
```

After updating the init script run:
```
sudo systemctl daemon-reload
```

Note: `update-rc.d` is deprecated. Use `insserv` instead.

## Interacting with the service

### Starting
```
sudo service particle-agent start
```

### Stopping
```
sudo service particle-agent stop
```

### See what's running
```
sudo service particle-agent status
```

### View logs
```
cat /var/log/particle-agent.log
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

TODO: the following may not be accurate.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/particle-iot/particlepi.


## Building a Debian package

Prerequisites:
- `gem2deb`
- Make sure rbenv or RVM shims (Ruby version managers) are not in your path

If gem is released to RubyGem, run
```
gem2deb -p particle-agent particle-agent
```

Or build the gem locally
```
gem build *.gemspec
gem2deb -p particle-agent *.gem
```

### Development notes

Communicate with child processes
https://www.rubytapas.com/2016/06/16/episode-419-subprocesses-part-4-redirection/

```
input, output = IO.pipe

pid = Process.spawn "exec", "arg", out: output

Process.waitpid(pid)
input.close
input.read
```

>>

```
rd, wr = IO.pipe

if fork
  wr.close
  puts "Starting read"
  puts "Parent got: <#{rd.read}>"
  rd.close
  Process.wait
else
  rd.close
  sleep 1
  puts "Sending message to parent"
  wr.write "Hi Dad"
  wr.close
end
```

>>

Trap SIGCHLD when child exits
https://www.rubytapas.com/2016/06/30/episode-423-subprocesses-part-5-sigchld/

```
trap("CHLD") do
  pid = Process.waitpid(-1)
  pids[pid] = :done
end
```
