# Particle Pi Agent

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

