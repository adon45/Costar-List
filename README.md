# Media Checklist

A Flutter app that presents a dynamic, per-assignment media checklist with
persistent local state. Runs on iOS, Android, and desktop/emulator targets
with no platform-specific APIs.

## Getting started

```bash
flutter pub get
flutter run
```

## What's included

- `lib/models/` — `MediaType`/`MediaTypeConfig` registry and the
  `DeliverableDef` / `DeliverableState` / `DeliverableItem` models.
- `lib/data/checklist_data.dart` — the static checklist definitions for
  every media type and sub-type described in the spec.
- `lib/state/checklist_provider.dart` — the `ChangeNotifier` that resolves
  a checklist's live main list + unavailable list from definitions and
  persisted per-item state, and saves/restores everything via
  `shared_preferences`.
- `lib/screens/` — `MediaTypesScreen` (first screen) and `ChecklistScreen`.
- `lib/widgets/` — `DeliverableTile`, `UnavailableSection`, `CounterWidget`,
  `MenuDrawer`, and the sub-type picker bottom sheet.
- `lib/theme/app_theme.dart` — the `#e5e5e5` / `#1e3a6f` / `#f78210` color
  theme applied across AppBars, buttons, toggles, the counter, and icons.

## How persistence works

Each assignment (media type + optional sub-type) gets its own storage key.
For every deliverable id, only three booleans are persisted:
`isCompleted`, `isAvailable`, `isExpanded`. The main list, the unavailable
list, and any "Alternative" tiles are all *derived* from those booleans
plus the static checklist definition every time the provider rebuilds —
so there's nothing extra to keep in sync, and switching assignments,
locking the phone, or force-closing the app never loses progress. The
last-opened assignment is also remembered so relaunching the app drops
the user back into the same checklist.

## Adding real example photos

`DeliverableTile` will render `DeliverableDef.exampleImage` via
`Image.asset` if you set one and register the asset path under `flutter:
assets:` in `pubspec.yaml`. Until then, every "More Info" panel shows a
placeholder box so the UI is fully wired up.

## Extending a "Coming Soon" media type

1. Add its checklist to `lib/data/checklist_data.dart`.
2. Flip `comingSoon: false` (and add `subtypes` if needed) in
   `lib/models/media_type.dart`.

That's it — the Media Types screen, drawer, and checklist screen all read
from that single registry.
