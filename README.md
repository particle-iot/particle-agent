# Particle Pi Agent

This program supervises the Particle firmware executable running on
Raspberry Pi.

## Installing the service

```
sudo cp init/particlepi /etc/init.d
sudo insserv mydaemon
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

