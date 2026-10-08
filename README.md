# UTC Clock

A macOS menu bar clock that shows the time in UTC. Click it to copy the current time as an RFC 3339 timestamp with microseconds, such as `2026-10-08T13:15:02.123456Z`; its clock icon turns into a green clipboard for a second to confirm the copy. Right-click or Control-click it for Quit.

## Install

With Homebrew, which builds it from source and starts it at every login:

```
brew install hhsnopek/tap/utc-clock
brew services start utc-clock
```

Or from a clone:

```
make install
```

This builds `UTC Clock.app` with the Swift compiler from the Xcode Command Line Tools and copies it to `/Applications` (set `PREFIX` to change that). It is built on each Mac rather than downloaded, because Gatekeeper blocks a downloaded app that is not notarized, and only checks downloaded ones.

Start it at login from System Settings, General, Login Items.
