# sddm-theme-slickgreeter

An unofficial [SDDM](https://github.com/sddm/sddm) theme laid out like Linux Mint's
[Slick Greeter](https://github.com/linuxmint/slick-greeter), for people who like Slick
Greeter but use SDDM, for example for a login screen on Wayland.

The users sit in a column on Slick Greeter's 40 px grid, with the chosen one in a
blurred, rounded box holding the password entry and the session badge (click it for
the session list). A blurred top bar shows the host name, keyboard layout, clock and
power menu, and there is the "Goodbye. Would you like to..." shutdown dialog. The icons
and session badges are Slick Greeter's own.

## Options

Options are in `slick/theme.conf`. Change them in `theme.conf.user` next to it, which
SDDM reads over `theme.conf` and the installer keeps, or with
[sddm-settings](https://github.com/SyberHexen/sddm-settings) (Login Window), which shows
them when this theme is selected:

| Option | |
|---|---|
| `background` | Picture behind the login screen (absolute path, readable by the `sddm` user); empty for `backgroundColor` |
| `backgroundColor` | Colour without a picture, and around a scaled or centered one |
| `backgroundFill` | `zoom`, `scaled`, `stretched` or `centered` |
| `stretchBackgroundAcrossMonitors` | One picture across all monitors instead of one per monitor |
| `monitor` | The monitor the login box is on: `auto` (SDDM's primary) or a connector name such as `DP-1` |
| `contentAlign` | `left`, `center` or `right` |
| `font`, `clockFormat` | Font family; clock format in Qt's time format (`HH:mm`, `h:mm AP`) |
| `showHostname`, `showClock`, `showPower` | Top bar items |
| `showUserList`, `showManualLogin`, `hiddenUsers` | The user list, an entry for typing a user name, user names not to list (comma separated) |
| `scale` | `auto` (2 on screens 1800 px or more high) or a number |

## Requirements

SDDM 0.21 with its Qt 6 greeter, Qt 6.5 or later (`QtQuick.Effects`). Works on X11 and,
with SDDM's Wayland login screen, on Wayland. Tested with SDDM 0.21, KWin 6.8 and Qt 6.12
on Arch Linux.

## Install

```sh
sudo ./install.sh
```

It installs the theme as `/usr/share/sddm/themes/slick`, keeping the `theme.conf.user`
there. Then choose it: `Current=slick` under `[Theme]` in a file in
`/etc/sddm.conf.d/`, or in sddm-settings. To try it without switching login managers:

```sh
sddm-greeter-qt6 --test-mode --theme slick
```

## Notes

- On Wayland, Qt can name the wrong monitor for a login screen window once it is shown;
  the theme works out each window's monitor from its size instead.
- For running the login screen on Wayland under KWin, its known KWin issues and the
  settings KWin needs (numlock, primary monitor, HDR), see
  [sddm-settings](https://github.com/SyberHexen/sddm-settings).

## Credits and licences

This is an unofficial project, not affiliated with Linux Mint or the Cinnamon
project.

- **Slick Greeter** (Linux Mint, based on Canonical's Unity Greeter) is what the theme
  is modelled on. Its layout (grid, sizes, colours, texts) was taken from its source;
  the theme's code is new. Its icons are included unchanged: Copyright © 2011-2013
  Canonical Ltd, © 2017 Clement Lefebvre, GPL-3.0.
- **Session badges** in `slick/assets/badges`, from Slick Greeter: Copyright © 2013
  zombifier, [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/), unchanged.

See [`slick/assets/CREDITS.md`](slick/assets/CREDITS.md) for the included files.

Licensed under the GNU GPL version 3 (GPL-3.0-only, see `LICENSE`), as Slick Greeter
is; the session badges keep their CC BY 3.0 licence.
