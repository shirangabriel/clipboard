# Clipboard

A macOS menu bar clipboard utility for text history, user sections, and speed-dial favorites.

## MVP Decisions

- Capture text clipboard history automatically.
- Store everything for now; privacy filtering and biometric unlock are later work.
- Persist app state in JSON at `~/Library/Application Support/Clipboard/clipboard.json`.
- Keep a compact menu bar popover.
- Show search at the top.
- History defaults to 20 retained text items.
- No default user sections on first launch.
- User-created sections are independently collapsible and persisted.
- Click an item to copy it and show copied feedback.
- Drag history items into sections; drag section items between sections or within a section.
- Hover rows to reveal delete and favorite actions.
- Favorites are independent text copies with optional display names, limited to 9 speed-dial slots.
- Favorites only show assigned slots, not empty slots.
- `Command+Shift+V` opens the popover.
- `Control+Option+Command+1...9` copies Favorite slots directly without opening the popover.

## Build

```sh
swift build
```

Run the debug executable:

```sh
.build/debug/Clipboard
```
