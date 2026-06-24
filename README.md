# Clipboard

A macOS menu bar clipboard utility for text history, user sections, and speed-dial favorites.

## Features

- Captures text clipboard history automatically.
- Keeps a compact menu bar popover with search at the top.
- Lets you organize saved text into custom collapsible sections.
- Supports speed-dial favorites in slots 1 through 9.
- Copies a selected item back to the pasteboard and briefly shows `Copied!` in the menu bar.
- Opens from the keyboard with `Command+Shift+V`.
- Copies favorite slots directly with `Control+Option+Command+1...9`.
- Checks for app updates automatically using Sparkle.

## Requirements

- macOS 14 or newer.
- Swift 6 toolchain for source builds.
- Xcode command line tools:

```sh
xcode-select --install
```

## Install

### Homebrew

Clipboard is distributed as a Homebrew Cask from `shirangabriel/homebrew-tap`.

```sh
brew tap shirangabriel/tap
brew install --cask clipboard
```

The cask installs `Clipboard.app`. Launch it from Finder, Spotlight, or:

```sh
open /Applications/Clipboard.app
```

### Build From Source

Clone the repository and build the Swift package:

```sh
git clone https://github.com/shirangabriel/clipboard.git
cd clipboard
swift build
```

Run the debug executable:

```sh
.build/debug/Clipboard
```

Build and launch the app bundle:

```sh
script/build_and_run.sh
```

## Usage

- Click the clipboard icon in the macOS menu bar to open the popover.
- Use search to filter clipboard history, user sections, and favorites.
- Click an item to copy it back to the pasteboard.
- Drag history items into sections, or drag section items between sections.
- Hover rows to reveal delete and favorite actions.
- Use `Command+Shift+V` to open Clipboard without clicking the menu bar.
- Use `Control+Option+Command+1...9` to copy an assigned favorite slot directly.

## Privacy

Clipboard stores app state locally as JSON at:

```text
~/Library/Application Support/Clipboard/clipboard.json
```

Current builds retain text clipboard history locally. Do not use Clipboard for secrets unless you are comfortable with that local retention behavior.

## Development

```sh
swift build
swift test
```

Build and run the app bundle:

```sh
script/build_and_run.sh
```

Verify that the app launches:

```sh
script/build_and_run.sh --verify
```

Create a release zip and print its SHA-256 checksum:

```sh
script/build_and_run.sh --package 0.1.2
```

Create a release zip and signed Sparkle appcast:

```sh
script/build_and_run.sh --appcast 0.1.2
```

Release artifacts are written to `dist/`, which is ignored by git.

## Contributing

Bug reports, feature requests, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, test, and review expectations.

## License

Clipboard is released under the [MIT License](LICENSE).
