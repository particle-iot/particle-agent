# Particle Pi Agent [![Build Status](https://travis-ci.com/spark/particlepi.svg?token=xZbAFMKBu94uE5pFYFFK&branch=master)](https://travis-ci.com/spark/particlepi)

This program supervises the Particle firmware executable running on
Raspberry Pi.

## Architecture

Particle Pi is a Ruby application. The logic lives inside <lib>

The Agent is an executable that runs as a background service (daemon).
The agent executable is <bin/agent> and does things like command line parsing.
It delegates to the [Daemon class](lib/daemon.rb) to manage a PID file,
a log file and fork the process to the background.

The service description for the Agent is a System V init script in
<init/particlepi>. I tried making a systemd service but couldn't find
the right documentation to set that up.

## Installing the service

```
sudo cp init/particlepi /etc/init.d
sudo ln -s $PWD/bin/agent /usr/local/bin/particlepi-agent
sudo insserv particlepi
```

After updating the `init/particlepi` script run:
```
sudo systemctl daemon-reload
```

Note: `update-rc.d` is deprecated. Use `insserv` instead.

## Start the service

```
sudo service particlepi start
```

Other commands:
```
$ sudo service particlepi
Usage: /etc/init.d/particlepi {start|stop|restart|status}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/spark/particlepi.



## Releasing software to a Debian personal package archive (PPA)

Our PPA is https://launchpad.net/~particleio/+archive/ubuntu/particlepi

1. Create an account on Launchpad
2. Create a team on Launchpad
3. Create a PPA on Launchpad
https://help.launchpad.net/Packaging/PPA/BuildingASourcePackage
4. Upload a source package to Launchpad
https://help.launchpad.net/Packaging/PPA/Uploading
5. Launchpad will build your package

To get added to the Launchpad team, launch https://launchpad.net/people/+me, register an account and ask one of the existing team members to add you to the particleio team.

### Development notes

Communicate with child processes
https://www.rubytapas.com/2016/06/16/episode-419-subprocesses-part-4-redirection/

`
input, output = IO.pipe

pid = Process.spawm "exec", "arg", out: output

Process.waitpid(pid)
input.close
input.read
`

>>

`
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
`

>>

Trap SIGCHLD when child exits
https://www.rubytapas.com/2016/06/30/episode-423-subprocesses-part-5-sigchld/

`
trap("CHLD") do
  pid = Process.waitpid(-1)
  pids[pid] = :done
end
`
