# cranberry

A BSP tiling window manager for macOS.

## Why cranberry?

- **No SIP to disable.** Switching Spaces, sending windows to another Space and
  moving them between displays all work with System Integrity Protection on.
- **macOS's own Spaces.** Your Spaces stay the ones Mission Control shows, with
  labels (`cberry space web`) and rules that send an app's windows where they belong.
- **Shortcuts built in.** `cberry bind 'alt - h : cberry focus left'` in your config
  is all it takes; no separate hotkey daemon, and `cberry` commands run without
  starting a process.
- **Smooth.** Windows slide into place on macOS's own animation curve.
- **The mouse works too.** Hold a key to move or resize any window, drag one onto
  another to swap them or split it, and turn on focus follows mouse if you like.
- **Floating when you want it.** Scratchpads for an app you want at hand on every
  Space, grid placement for floating windows, and a whole Space can stay untiled.
- **One config file**, a plain shell script, and `cberry doctor` when something is off.

## Install

```sh
brew install emreekici3/formulae/cranberry

mkdir -p ~/.config/cranberry
cp "$(brew --prefix)/share/cranberry/cberryrc" ~/.config/cranberry/cberryrc

cberry install
cberry start
```

Then enable `cberry` under *System Settings → Privacy & Security → Accessibility*.

If something is off, `cberry doctor` says what.

To update, run `brew upgrade cranberry` and `cberry restart`. If windows stop moving, remove `cberry` from the Accessibility list, add it again and run `cberry restart`.

### Manual install

You need [Rust](https://rustup.rs).

```sh
git clone https://github.com/emreekici3/cranberry.git
cd cranberry
cargo install --path . --root ~

echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshenv
source ~/.zshenv

mkdir -p ~/.config/cranberry
cp examples/cberryrc ~/.config/cranberry/cberryrc

cberry install
cberry start
```

Enable `~/bin/cberry` under Accessibility as above. To update, run `git pull`, the `cargo install` line and `cberry restart`.

## Docs

- [Commands](docs/commands.md)
- [Keyboard shortcuts](docs/shortcuts.md)
- [Mouse](docs/mouse.md)
- [Spaces and displays](docs/spaces.md)
- [Configuration](docs/configuration.md)

## License

MIT
