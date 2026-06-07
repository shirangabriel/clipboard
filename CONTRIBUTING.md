# Contributing

Thanks for helping improve Clipboard. Keep changes focused and easy to review.

## Setup

Clipboard is a Swift Package macOS app.

Requirements:

- macOS 14 or newer.
- Swift 6 toolchain.
- Xcode command line tools.

Build and test:

```sh
swift build
swift test
```

Run the app bundle:

```sh
script/build_and_run.sh
```

Verify launch behavior:

```sh
script/build_and_run.sh --verify
```

## Pull Requests

- Keep pull requests scoped to one bug fix, feature, or cleanup.
- Include tests for model, filtering, persistence, or behavior changes when practical.
- Run `swift build` and `swift test` before opening a pull request.
- Do not include generated build output, release zips, or files from `dist/`.
- Avoid unrelated refactors in feature or bug-fix pull requests.

## Coding Style

- Follow the existing SwiftUI and Swift style in `Sources/Clipboard`.
- Prefer small views and focused model helpers over broad rewrites.
- Keep AppKit and Carbon interop narrow and localized.
- Use clear names for user-facing behaviors and persisted data.

## Issues

Please include:

- macOS version.
- Clipboard version or commit SHA.
- Steps to reproduce.
- Expected behavior.
- Actual behavior.

For feature requests, describe the workflow you want to improve and any privacy or keyboard-shortcut implications.
