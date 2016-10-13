# Particle Pi Agent

This program supervises the Particle firmware executable running on
Raspberry Pi.

## Installing the init service

```
sudo cp init/particlepi /etc/init.d
sudo insserv mydaemon
```

Note: `update-rc.d` is deprecated. Use `insserv` instead.
