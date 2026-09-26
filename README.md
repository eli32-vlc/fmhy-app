# FMHY X

Flutter client for [FreeMediaHeckYeah](https://fmhy.net) — the free media resource index.

## Features

- Browse and search every category from the FMHY single-page feed
- Category detail with notes and subsections
- Featured / regional / related badges, plus alternate links per entry
- Favorites and Recently Viewed, persisted locally
- Open, copy, and share any entry URL
- Export and import favorites and history as JSON

## Download

Get the latest build from the [releases page](https://github.com/eli32-vlc/fmhy-app/releases/latest) — public, no sign-in needed.

## Build

```bash
flutter pub get
flutter test
flutter build apk --release
```

## CI

Every push to `main` runs analyze, tests, and builds Android APKs plus an
unsigned iOS `.ipa`. Pushing a `v*` tag also publishes both to the
[releases page](https://github.com/eli32-vlc/fmhy-app/releases).

## Content

Data comes from [fmhy.net](https://fmhy.net) and the app is affiliated with the project, but it is not an official release.
