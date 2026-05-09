# Stickies

A native macOS 26+ sticky-notes app inspired by Apple Stickies.

This first version focuses on local behavior:

- independent floating note windows
- always-on-top notes
- automatic persistence
- Markdown/plain-text note files
- hot reload when files change on disk
- file-per-note storage under `~/.stickies/notes`

## Run

```sh
./script/build_and_run.sh
```

The script builds the SwiftPM target, stages `dist/Stickies.app`, and launches it
as a foreground macOS app.

## Test

```sh
swift test
```

