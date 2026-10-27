# Pane personal fork

Pane is a personal, MIT-licensed fork of [Search](https://github.com/driceroland/Search).
The original Search app and its data stay separate.

## Build

Requires macOS 14 or later and Xcode 16 or later. From this checkout:

```sh
SEARCH_PERSONAL_FORK=1 ./build.sh release app
```

This creates an ad-hoc signed `build/Pane.app` with bundle ID
`com.henryvn27.pane`. Its preferences, Application Support folder, WebKit
website data and AI keychain entries use the Pane identity. The build script
does not make a disk image, notarize the app or install it.

## Keep up with Search

Pane does not use Search's binary updater: an official Search release has a
different bundle ID and must never replace this custom build. Updates come
from source instead. When you create a GitHub fork, configure it as `origin`
and Search as `upstream` (replace the placeholder with your fork URL):

```sh
git remote rename origin upstream
git remote add origin <your-fork-url>
git fetch --unshallow upstream
```

Then bring upstream changes into the feature branch and rebuild:

```sh
git fetch upstream
git merge upstream/main
SEARCH_PERSONAL_FORK=1 ./build.sh release app
```

Review conflicts before rebuilding. A GitHub fork tracks source history; it
does not make official Search binaries preserve Pane's changes.

## Keyboard changes

- `⌘F` remains Find on Page; editable fields and page shortcuts keep their
  existing first chance. `⌃F` remains available for macOS text navigation.
- Fn/Globe combinations pass through to macOS, including its Move & Resize
  and Fill window shortcuts.
- With Split View enabled, `⌥⌘N` splits the current page. `⌃⌘[` / `⌃⌘]`
  focus the left or right pane, `⌃⌘P` focuses the other pane, `⌃⇧⌘S`
  swaps pages and `⌃⇧⌘D` separates the pair. The three new actions are
  also in Tabs and Shortcuts settings.
- These split commands control Search's two page panes. macOS window tiling
  still controls the app window and works independently.

The editable icon source is in `ForkIcon/icon.swift`; the build writes the
icon into Pane.app and saves a 1024-pixel preview at `ForkIcon/preview.png`
(also copied to `build/Pane-icon-preview.png`).
