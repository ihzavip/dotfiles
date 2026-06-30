# system/ — root-owned config (NOT stow-managed)

These files live under `/etc` and are owned by root, so they **cannot** be
symlinked with `stow` (which targets `$HOME`). This tree mirrors their real
absolute paths for reference; install them by copying manually with `sudo`.

## Files

### `etc/X11/xorg.conf.d/20-tearfree.conf`
Enables the modesetting driver's **TearFree** (driver-level vsync) on the Intel
iGPU. Needed because `picom`'s `unredir-if-possible = true` lets fullscreen apps
bypass the compositor — TearFree restores vsync for them so fullscreen video and
games don't tear on the external monitor.

Install:

```bash
sudo cp system/etc/X11/xorg.conf.d/20-tearfree.conf /etc/X11/xorg.conf.d/
# then log out and back in (restarts X)
```

Verify after relogin:

```bash
grep -i tearfree /var/log/Xorg.0.log   # expect a "TearFree" enabled line
```

Revert: `sudo rm /etc/X11/xorg.conf.d/20-tearfree.conf` and relogin.
