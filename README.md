# qsm-shell

Reusable QML components and design tokens for Qt 6 surfaces.

It knows nothing about any application. Everything an application owns —
services, state, persistence, compositor integration, which keys mean what —
stays with the application; this supplies the vocabulary it draws with.

It provides components, tokens, and the edge silhouette shader. It does not
yet provide the `ShellBorder` system that shader exists for.

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
`Interaction` is the one place you state a fact components cannot see for
themselves (whether a hover may claim a selection).

Public types are listed in `qml/QsmShell/Components/qmldir`.

## What is in it

| | |
| --- | --- |
| **foundation** | `Prose` (ten type roles), `SvgIcon`, `Card`, `Divider`, `StateLayer` |
| **controls** | `Capsule`, `IconButton`, `TextField`, `Field`, `Switch`, `Checkbox`, `Segmented`, `Slider` |
| **lists** | `ListRow`, `Menu`, `SelectionMark`, `ScrollArea`, `ScrollCue`, `Section`, `Disclosure` |
| **state** | `Spinner`, `ProgressBar`, `Skeleton`, `Callout`, `EmptyState` |
| **readouts** | `Badge`, `Meter`, `Stat`, `StatRing`, `Sparkline`, `KeyValueRow`, `Marquee`, `ColorSwatch`, `Kbd`, `Avatar` |
| **surfaces** | `Popover`, `Dialog`, `Scrim`, `NotificationCard`, `MonthCalendar`, `ActionTile` |
| **behaviour** | `ArmedAction` |
| **shader** | `qml/QsmShell/shaders/edgemelt.frag` plus its committed `.qsb` |

## Develop

```bash
npm run capture -- <scenario> /tmp/out.png
npm test
bash scripts/build-shaders   # only after editing a .frag; commit .frag + .qsb together
```

- `capture` renders one native QML preview offscreen; scenario names come from
  `previews/scenarios.json`, and every public type has one.
- `test` regenerates tokens, lints QML, and runs the native smoke and the
  interaction tests.

A component is looked at in native QML and nowhere else.

The shader is the one thing here that is not pure QML. Both the `.frag` and the
built `.qsb` are committed, because Quickshell loads the `.qsb` at runtime and
no consumer should need a Qt shader toolchain to run. `npm test` fails if the
committed `.qsb` does not match a rebuild of its `.frag`.

Add visible behavior first. Verify it in native QML, then add one focused
regression check if the behavior can realistically regress.

## Next Milestones

1. ~~Port the existing edge shader unchanged.~~ Done 2026-09-06.
2. Render one `ShellBorder` with one dynamically anchored rollout.
3. Review that result live before adding nesting, welding, or fullscreen rules.
