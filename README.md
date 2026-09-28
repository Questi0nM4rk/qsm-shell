# qsm-shell

Reusable QML components and design tokens for Qt 6 surfaces.

It knows nothing about any application. Everything an application owns —
services, state, persistence, compositor integration, which keys mean what —
stays with the application; this supplies the vocabulary it draws with.

It provides components, tokens, the edge silhouette shader, and the
`ShellBorder` system that shader exists for: a host that owns the rollout
registries and publishes plain rectangles, leaving Wayland, monitors and input
masks entirely to the consumer.

## Use

Add `qml/` to the QML import path, then install your own token source:

```qml
import qs.QsmShell.Components
import qs.QsmShell.Style

Binding {
    target: Style
    property: "backend"
    value: MyTheme          // any object exposing the token names
}

Capsule {
    icon: "bell"
    label: "Notifications"
    variant: "primary"
}
```

`Style` resolves every value as *your backend first, the library's generated
token as the fallback* — so `Tokens` is the DEFAULT theme, never the theme.

Sizes work the same way. A sized type takes a preset NAME, `size: "md"`, and
resolves it through `Style.size("<Type>", name)` against the theme's size
table (`sizes.<Type>.<name>`, defaults in `tokens/deep-night.json`). Your
backend's `sizes` extends or overrides that table, so `sizes: { Switch: { xl: 40 } }`
makes `Switch { size: "xl" }` valid in your project. The resolved number
(`knobSize`, `thumbSize`, `fieldHeight`) stays settable directly when one
call site needs one value. `workbench/theme.json` is the consumer-shaped theme
the provider stories and captures run under, extra presets included.
`Interaction` is the one place you state a fact components cannot see for
themselves (whether a hover may claim a selection).

Public types are listed in `qml/QsmShell/Components/qmldir`.

## What is in it

| | |
| --- | --- |
| **foundation** | `Prose` (ten type roles), `SvgIcon`, `Surface` (a body on the ladder), `Card`, `Divider`, `StateLayer` |
| **controls** | `Capsule`, `IconButton`, `TextField`, `Field`, `ControlLabel`, `Switch`, `Checkbox`, `Segmented`, `Slider` (one or two thumbs) |
| **lists** | `ListRow`, `Menu`, `SelectionMark`, `ScrollArea`, `ScrollCue`, `Section`, `Disclosure` |
| **state** | `Spinner`, `ProgressBar`, `Skeleton`, `Callout`, `EmptyState` |
| **readouts** | `Badge`, `Meter`, `Stat`, `StatRing`, `Sparkline`, `KeyValueRow`, `Marquee`, `ColorSwatch`, `Kbd`, `Avatar` |
| **surfaces** | `Popover`, `Dialog`, `Scrim`, `NotificationCard`, `NotificationCenter`, `NotificationStack`, `MonthCalendar`, `ActionTile` |
| **behaviour** | `ArmedAction`, `ScenePointer` |
| **frame** | `ShellBorder`, `Rollout` |
| **shader** | `qml/QsmShell/shaders/edgemelt.frag` plus its committed `.qsb` |

## Develop

```bash
npm run preview -- <scenario>
npm run capture -- <scenario> /tmp/out.png
npm run unit -- <Type>            # --window runs it on the compositor instead
npm test
bash scripts/build-shaders        # only after editing a .frag; commit .frag + .qsb together
```

- `preview` delegates to the sibling generic workbench with this repo as the
  provider; story names come from `workbench/stories.json`.
- `capture` delegates to the same provider workbench entry point.
- `unit` runs one type's test file under `tests/units/` (falling back to
  `tests/interaction/` for types not yet migrated).
- `test` regenerates tokens, lints QML, and runs the native smoke check plus
  every test directory.
- Provider runtime QML lives under `workbench/`; production components remain
  under `qml/QsmShell/Components/`.

A component is judged in a live native QML window and nowhere else. See
`AGENTS.md` for a unit's shape and the step-by-step loop for migrating one.

The shader is the one thing here that is not pure QML. Both the `.frag` and the
built `.qsb` are committed, because Quickshell loads the `.qsb` at runtime and
no consumer should need a Qt shader toolchain to run. `npm test` fails if the
committed `.qsb` does not match a rebuild of its `.frag`.

Build the feature, look at it in the live window, then add one regression
check only if the behaviour can realistically regress. No TDD, no plans, no
dated docs. `AGENTS.md` holds the direction and the component laws; the
project skill `develop-component` holds the step loop for one type.

## Next

Open items, in order, live in `docs/BACKLOG.md`.
