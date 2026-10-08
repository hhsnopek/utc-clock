# UTC Clock

A macOS menu bar clock that shows the time in UTC. Click it to copy the current time as a Postgres `timestamptz`, such as `2026-10-08 13:15:02.123456+00`. Right-click or Control-click it for Quit.

## Install

```
make install
```

This builds `UTC Clock.app` with the Swift compiler from the Xcode Command Line Tools and copies it to `/Applications` (set `PREFIX` to change that). It is built on each Mac rather than downloaded, because Gatekeeper blocks a downloaded app that is not notarized, and only checks downloaded ones.

Start it at login from System Settings, General, Login Items.
